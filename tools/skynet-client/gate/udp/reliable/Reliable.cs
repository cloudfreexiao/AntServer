using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Assertions;

namespace Skynet.DotNetClient.Gate.UDP
{
    public class Node
    {
        public object Data { get; private set; }
        public Node Next { get; set; }
        public Node(object data)
        {
            Data = data;
        }
    }
    public class RQueue
    {
        public Node head;
        public Node tail;
        public RQueue() { }
        
        public void Enqueue(int data)
        {
            var newNode = new Node(data);
            if (head == null)
            {
                head = newNode;
                tail = head;
            }
            else
            {
                tail.Next = newNode;
                tail = tail.Next;
            }
            Count++;
        }
        public object Dequeue()
        {
            if (head == null)
            {
                throw new Exception("Queue is Empty");
            }
            var result = head.Data;
            head = head.Next;
            return result;
        }

        public object Peek()
        {
            if (head == null)
            {
                throw new Exception("Queue is Empty");
            }

            return head.Data;
        }
        
        public int Count { get; private set; } = 0;
    }
    
    public abstract class ReliableMessage
    {
        public byte[] buffer = null;
        public int sz = 0;
        public int id = 0;
        public int tick = 0;
    }

    public abstract class ReliablePackage
    {
        public byte[] buffer = null;
        public int sz = 0;
    }

    public static class ReliableConst
    {
        public const int TypeIgnore = 0;
        public const int TypeCorrupt = 1;
        public const int TypeRequest = 2;
        public const int TypeMissing = 3;
        public const int TypeNormal = 4;

        // GeneralPackage 512
        public const int GeneralPackage = 128;
    }
    
    public class PackageBuffer
    {
        private readonly ByteBuffer _buffer = ByteBuffer.Allocate(4);
        private int _num = 0;

        public void PackRequest(int id, int tag)
        {
            var num = ReliableConst.GeneralPackage - _num;
            if (num < 3) {
            }

            FillHeader(tag, id);
//            buffer.WriteByte(((id & 0x7f00) >> 8) | 0x80);
//            buffer.WriteByte(id & 0xff);
        }

        private void NewPackage()
        {
            
        }
        private void FillHeader(int head, int id)
        {
            if(head < 128)
            {
                _buffer.WriteByte(head);
            } 
            else 
            {
                _buffer.WriteByte(((head & 0x7f00) >> 8) | 0x80);
                _buffer.WriteByte(head & 0xff);
            }

            _buffer.WriteByte((id & 0xff00) >> 8);
            _buffer.WriteByte(id & 0xff);
        }
    }
    
    public class Reliable
    {
        private int _corrupt; // 超过n个tick连接丢失
        private int _expired; // 发送的消息最大保留n个tick
        private int _sendDelay; // n个tick发送一次消息包

        private int _currentTick;
        private int _lastSendTick;
        private int _lastExpiredTick;
        private int _sendId;
        private int _recvIdMin = 0;
        private int _recvIdMax;


//        private int _missingTime = 100; // n纳秒没有收到消息包就认为消息丢失，请求重发

        private RQueue _sendQueue = new RQueue(); // user packages will send
        private RQueue _recvQueue = new RQueue(); // the packages recv
        private RQueue _sendHistory = new RQueue(); // user packages already send

//        private readonly List<ReliablePackage> _sendPackages = new List<ReliablePackage>(); // returns by rudp_update

        private List<int> _sendAgain = new List<int>();
        //	struct message *free_list;	// recycle message struct

        public Reliable(int sendDelay, int expired)
        {
            _expired = expired;
            _sendDelay = sendDelay;
        }
        
        public List<ReliablePackage> Update(byte[] buffer, int sz, int tick)
        {
            _currentTick += tick;

            if (_currentTick >= _lastExpiredTick + _expired) {
                ClearSendExpired(_lastExpiredTick);
                _lastExpiredTick = _currentTick;
            }

            if (_currentTick < _lastSendTick + _sendDelay) return null;
            var sendPackages = OutPut();
            _lastSendTick = _currentTick;
            return sendPackages;
        }

        private void ClearSendExpired(int lastExpiredTick)
        {
            while (true)
            {
                if (_sendHistory.Count <= 0) return;

                //TODO: free all the messages before tick 待检查
                if (_sendHistory.Peek() is ReliableMessage v && v.tick >= lastExpiredTick) return;

                _sendHistory.Dequeue();
            }
        }

        private List<ReliablePackage> OutPut()
        {
            var tmp = new PackageBuffer();
            RequestMissing(ref tmp);
            ReplyRequest(ref tmp);
            SendMessage(ref tmp);
            return null;
        }


        private void RequestMissing(ref PackageBuffer tmp)
        {
            var id = _recvIdMin;
            var h = _recvQueue.head;
            while (h != null)
            {
                var m = h.Data as ReliableMessage;
                Debug.Assert(m != null && m.id >= id);
                if (m.id > id)
                {
                    int i;
                    for (i = id; i < m.id; i++)
                    {
                        tmp.PackRequest(i, ReliableConst.TypeRequest);
                    }
                }

                id = m.id + 1;
                h = h.Next;
            }
        }


        private void ReplyRequest(ref PackageBuffer tmp)
        {
            
        }

        private void SendMessage(ref PackageBuffer tmp)
        {
            
        }


    }
}