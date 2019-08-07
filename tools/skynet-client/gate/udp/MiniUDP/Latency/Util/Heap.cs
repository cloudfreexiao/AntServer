/*
 *  MiniUDP - A Simple UDP Layer for Shipping and Receiving Byte Arrays
 *  Copyright (c) 2016 - Alexander Shoulson - http://ashoulson.com
 *
 *  This software is provided 'as-is', without any express or implied
 *  warranty. In no event will the authors be held liable for any damages
 *  arising from the use of this software.
 *  Permission is granted to anyone to use this software for any purpose,
 *  including commercial applications, and to alter it and redistribute it
 *  freely, subject to the following restrictions:
 *  
 *  1. The origin of this software must not be misrepresented; you must not
 *     claim that you wrote the original software. If you use this software
 *     in a product, an acknowledgment in the product documentation would be
 *     appreciated but is not required.
 *  2. Altered source versions must be plainly marked as such, and must not be
 *     misrepresented as being the original software.
 *  3. This notice may not be removed or altered from any source distribution.
*/

#if DEBUG
using System;
using System.Collections.Generic;

namespace MiniUDP.Util
{
  internal class Heap<T>
  {
    private const int InitialCapacity = 0;
    private const int GrowFactor = 2;
    private const int MinGrow = 1;

    private T[] _heap = new T[Heap<T>.InitialCapacity];

    public int Count { get; private set; }
    private int Capacity { get; set; } = Heap<T>.InitialCapacity;

    private Comparer<T> Comparer { get; }

    public Heap()
    {
      Comparer = Comparer<T>.Default;
    }

    public Heap(Comparer<T> comparer)
    {
      Comparer = comparer ?? throw new ArgumentNullException("comparer");
    }

    public void Clear()
    {
      Count = 0;
    }

    public void Add(T item)
    {
      if (Count == Capacity)
        Grow();
      _heap[this.Count++] = item;
      BubbleUp(Count - 1);
    }

    public T GetMin()
    {
      if (Count == 0)
        throw new InvalidOperationException("Heap is empty");
      return _heap[0];
    }

    public T ExtractDominating()
    {
      if (Count == 0)
        throw new InvalidOperationException("Heap is empty");
      var ret = _heap[0];
      Count--;
      Swap(this.Count, 0);
      BubbleDown(0);
      return ret;
    }

    private bool Dominates(T x, T y)
    {
      return Comparer.Compare(x, y) <= 0;
    }

    private void BubbleUp(int i)
    {
      if (i == 0)
        return;
      if (Dominates(this._heap[Heap<T>.Parent(i)], _heap[i]))
        return; // Correct domination (or root)

      Swap(i, Heap<T>.Parent(i));
      BubbleUp(Heap<T>.Parent(i));
    }

    private void BubbleDown(int i)
    {
      var dominatingNode = Dominating(i);
      if (dominatingNode == i)
        return;
      Swap(i, dominatingNode);
      BubbleDown(dominatingNode);
    }

    private int Dominating(int i)
    {
      var dominatingNode = i;
      dominatingNode =
        GetDominating(Heap<T>.YoungChild(i), dominatingNode);
      dominatingNode =
        GetDominating(Heap<T>.OldChild(i), dominatingNode);
      return dominatingNode;
    }

    private int GetDominating(int newNode, int dominatingNode)
    {
      if (newNode >= Count)
        return dominatingNode;
      return Dominates(_heap[dominatingNode], _heap[newNode]) ? dominatingNode : newNode;
    }

    private void Swap(int i, int j)
    {
      T tmp = _heap[i];
      _heap[i] = _heap[j];
      _heap[j] = tmp;
    }

    private static int Parent(int i)
    {
      return (i + 1) / 2 - 1;
    }

    private static int YoungChild(int i)
    {
      return (i + 1) * 2 - 1;
    }

    private static int OldChild(int i)
    {
      return Heap<T>.YoungChild(i) + 1;
    }

    private void Grow()
    {
      var newCapacity = Capacity * Heap<T>.GrowFactor + Heap<T>.MinGrow;
      var newHeap = new T[newCapacity];
      Array.Copy(this._heap, newHeap, Capacity);
      _heap = newHeap;
      Capacity = newCapacity;
    }
  }
}
#endif