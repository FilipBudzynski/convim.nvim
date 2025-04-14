package main

import (
	"bufio"
	"fmt"
	"log"
	"net"
	"time"
)

var (
	clients  = map[net.Conn]bool{}
	nvimBuff = []byte{}
)

func main() {
	l, err := net.Listen("tcp4", ":9999")
	if err != nil {
		log.Println(err)
		return
	}
	defer l.Close()
	fmt.Println("TCP server listening on port 9999")

	for {
		conn, err := l.Accept()
		if err != nil {
			log.Println(err)
			return
		}
		go handleConnection(conn)
	}
}

func handleConnection(conn net.Conn) {
	defer conn.Close()
	reader := bufio.NewReader(conn)

	if _, ok := clients[conn]; !ok {
		clients[conn] = true

		if len(nvimBuff) != 0 {
			go func(c net.Conn) {
				time.Sleep(200 * time.Millisecond)
				_, err := c.Write(nvimBuff)
				if err != nil {
					log.Println("buffer not sent:", err)
				} else {
					log.Println("sent buffer to new client")
				}
			}(conn)
		}
	}

	for {
		msg, err := reader.ReadString('\n')
        if err != nil { 
            log.Println("Read error:", err)
        }

		if len(nvimBuff) == 0 {
			nvimBuff = []byte(msg)
		}

		for c := range clients {
			if c == conn {
				continue
			}
			_, err := c.Write([]byte(msg))
			if err != nil {
				log.Println(err)
				return
			}
		}
	}
}
