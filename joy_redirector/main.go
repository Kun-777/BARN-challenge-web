package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"

	"github.com/aler9/goroslib"
	"github.com/aler9/goroslib/pkg/msgs/sensor_msgs"
	"github.com/aler9/goroslib/pkg/msgs/std_msgs"
	"github.com/gorilla/websocket"
)

type Inputs struct {
	Axes    [8]float32
	Buttons [15]int32
}

var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
}

var inputChan = make(chan Inputs)

func reader(conn *websocket.Conn) {
	for {
		messageType, p, err := conn.ReadMessage()
		if err != nil {
			log.Println(err)
			close(inputChan)
			return
		}

		input := Inputs{}
		json.Unmarshal(p, &input)
		inputChan <- input

		if err := conn.WriteMessage(messageType, p); err != nil {
			log.Println(err)
			close(inputChan)
			return
		}
	}
}

func ws_endpoint(res http.ResponseWriter, req *http.Request) {
	upgrader.CheckOrigin = func(r *http.Request) bool { return true }

	ws, err := upgrader.Upgrade(res, req, nil)
	if err != nil {
		log.Println(err)
	}

	log.Println("client successfully connected")

	reader(ws)
}

func setup_server_routes() {
	http.HandleFunc("/ws", ws_endpoint)
}

func controller_command_publish() {
	// create a node and connect to the master
	n, err := goroslib.NewNode(goroslib.NodeConf{
		Name:          "xbox_pub",
		MasterAddress: "127.0.0.1:11311",
	})
	if err != nil {
		panic(err)
	}
	defer n.Close()

	// create a publisher
	pub, err := goroslib.NewPublisher(goroslib.PublisherConf{
		Node:  n,
		Topic: "joy",
		Msg:   &sensor_msgs.Joy{},
	})
	if err != nil {
		panic(err)
	}
	defer pub.Close()

	var seq uint32 = 0

	for input := range inputChan {
		msg := &sensor_msgs.Joy{
			Header: std_msgs.Header{
				Seq:     seq,
				Stamp:   n.TimeNow(),
				FrameId: "remote",
			},
			Axes:    input.Axes[:],
			Buttons: input.Buttons[:],
		}
		pub.Write(msg)
		seq++
	}
}

func main() {
	go controller_command_publish()
	setup_server_routes()
	fmt.Println("joy redirector starting")
	log.Fatal(http.ListenAndServe(":8081", nil))
}
