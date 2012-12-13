echo off
echo "Testing -- Is RAM Drive R:\ available?"
echo "hsdio_stream_dual OUTFILE DIGFS FRAMESIZE FRAMECOUNT CARDNAME DIn TRIGGER CHANNUM BITCOUNT SIMULATE

del R:\HSDIO.binStop

echo "Not outputting to R:\HSDIO.out"
.\hsdio_stream_dual.exe R:\HSDIO.bin 50000000.000  500  5  D1  0  XX 96  16  0
