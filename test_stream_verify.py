import sys

# Perform a static check to verify correct changes in streamtools.pas
def verify_streamtools():
    try:
        with open('tools/streamtools.pas', 'r') as f:
            content = f.read()

        # Check for ReadBuffer and WriteBuffer
        if "AStream.ReadBuffer(strBase64[1], AStream.Size);" not in content:
             print("FAIL: ReadBuffer not found in Base64StreamToString")
             sys.exit(1)

        if "Result.WriteBuffer(EncodedStr[1], Length(EncodedStr));" not in content:
             print("FAIL: WriteBuffer not found in StringToBase64Stream")
             sys.exit(1)

        print("SUCCESS: Optimizations seem correctly applied based on static check.")
    except Exception as e:
        print(f"ERROR: {e}")
        sys.exit(1)

if __name__ == '__main__':
    verify_streamtools()
