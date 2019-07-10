using System;

public class SpStream {
    const int DEFAULT_SIZE = 32768;

    private byte[] mBuffer;
    private int mOffset;
    private int mLength;
    private int mPosition;
    private int mTail;

    public SpStream ()
		: this (DEFAULT_SIZE) {
    }

    public SpStream (int len)
        : this (new byte[len]) {
    }

    public SpStream (byte[] b) 
        : this (b, 0, b.Length) {
    }
	
	public SpStream (byte[] b, int o, int c)
		: this (b, 0, b.Length, -1) {
	}
	
	public SpStream (byte[] b, int o, int c, int t) {
        mBuffer = b;
        mLength = o + c;
        mOffset = o;
        mPosition = mOffset;

		if (t >= 0)
        	mTail = o + t;
		else 
			mTail = mPosition;
    }

	public void Reset () {
		mPosition = mOffset;
		mTail = mPosition;
	}

    public bool IsOverflow () {
        return (mPosition > mLength);
    }

    public byte ReadByte () {
        int pos = mPosition;
        mPosition += 1;
        return mBuffer[pos];
    }

    public bool ReadBoolean () {
        return (ReadByte () != 0);
    }

    public short ReadInt16 () {
        int pos = mPosition;
        mPosition += 2;
        return BitConverter.ToInt16 (mBuffer, pos);
    }

    public ushort ReadUInt16 () {
        int pos = mPosition;
        mPosition += 2;
        return BitConverter.ToUInt16 (mBuffer, pos);
    }

    public int ReadInt32 () {
        int pos = mPosition;
        mPosition += 4;
        return BitConverter.ToInt32 (mBuffer, pos);
    }

    public long ReadInt64 () {
        int pos = mPosition;
        mPosition += 8;
        return BitConverter.ToInt64 (mBuffer, pos);
    }

    public byte[] ReadBytes (int len) {
        byte[] bytes = new byte[len];
        for (int i = 0; i < len; i++) {
            bytes[i] = mBuffer[mPosition + i];
        }
        mPosition += len;
        return bytes;
    }

    public int Read (byte[] bytes) {
        return Read (bytes, 0, bytes.Length);
    }

    public int Read (byte[] bytes, int offset, int length) {
        for (int i = 0; i < length; i++) {
            if (mPosition >= mTail)
                return i;
            bytes[i + offset] = mBuffer[mPosition];
            mPosition++;
        }

        return length;
    }

	public void Write (short n) {
		if (CanWrite (2)) {
			mBuffer[mPosition + 0] = (byte)(n & 0xff);
			mBuffer[mPosition + 1] = (byte)((n >> 8) & 0xff);
		}
		PositionAdd (2);
    }

	public void Write (int n) {
		if (CanWrite (2)) {
			mBuffer[mPosition + 0] = (byte)(n & 0xff);
			mBuffer[mPosition + 1] = (byte)((n >> 8) & 0xff);
			mBuffer[mPosition + 2] = (byte)((n >> 16) & 0xff);
			mBuffer[mPosition + 3] = (byte)((n >> 24) & 0xff);
		}
		PositionAdd (4);
    }

	public void Write (long n) {
		if (CanWrite (2)) {
			mBuffer[mPosition + 0] = (byte)(n & 0xff);
			mBuffer[mPosition + 1] = (byte)((n >> 8) & 0xff);
			mBuffer[mPosition + 2] = (byte)((n >> 16) & 0xff);
			mBuffer[mPosition + 3] = (byte)((n >> 24) & 0xff);
			mBuffer[mPosition + 4] = (byte)((n >> 32) & 0xff);
			mBuffer[mPosition + 5] = (byte)((n >> 40) & 0xff);
			mBuffer[mPosition + 6] = (byte)((n >> 48) & 0xff);
			mBuffer[mPosition + 7] = (byte)((n >> 56) & 0xff);
		}
		PositionAdd (8);
    }

	public void Write (byte b) {
		if (CanWrite (1)) {
			mBuffer[mPosition] = b;
		}
		PositionAdd (1);
    }

    public void Write (byte[] bytes) {
        Write (bytes, 0, bytes.Length);
    }

	public void Write (byte[] bytes, int offset, int length) {
		if (CanWrite (length)) {
			Array.Copy (bytes, offset, mBuffer, mPosition, length);
		}
		PositionAdd (length);
    }
    public void CorrectLength(int c)
    {
        mTail = mPosition + c;
    }
	// NOTE : mPosition can be larger than mLength, but nothing will be wirten if so.
	//        using this feature to determine size required.
	private void PositionAdd (int n) {
		mPosition += n;
		if (mPosition > mTail) {
			mTail = mPosition;
			if (mTail > mLength)
				mTail = mLength;
		}
	}

	private bool CanWrite (int n) {
		return (mPosition + n <= mLength);
	}

    public int Position { 
        get { return mPosition; }
        set { mPosition = value; }
    }
	
	public int Offset { get { return mOffset; } }
	public int Length { get { return mTail - mOffset; } }
	public int Available { get { return mLength - mPosition; } }
	public int Capacity { get { return mLength; } }
	public int Tail { get { return mTail; } }
	public byte[] Buffer { get { return mBuffer; } }
}
