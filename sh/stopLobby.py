#!/usr/bin/python
import socket
import sys

#function example
def Usage():
    print "Usage is : ", sys.argv[0], "port"
    exit()

def Stop():
    # flow contorl
    if len(sys.argv) < 2:
        Usage()

    #variable
    port=0

    # exception
    try:
        port=int(sys.argv[1])
        print "port is %d " % (port)
        host=('127.0.0.1', port)
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.connect(host)
        # receive welcom from debug_console
        print "receive: ", s.recv(512)
        # send stop command
        s.send('call .game_shutdown "shutdown"\n')
        #read the result
        print "receive: ", s.recv(512)
        #bye
        s.close()
    except Exception , e:
        print "exit with exception : ", e
    finally:
        print "python bye"

if __name__ == "__main__":
    Stop()
