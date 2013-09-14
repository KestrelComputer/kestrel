package main

import (
	"bytes"
	"flag"
	"fmt"
	"io"
	"io/ioutil"
	"log"
	"os"
	"path"
)

type ImageFile struct {
	outputWriter io.Writer
	nbytes       int
	bytes        []byte
	wptr         int
	dptr         int
}

var startDIR = flag.Int("dirstart", 16, "Starting sector of directory extent")
var nDIR = flag.Int("ndir", 8, "Number of sectors in the directory extent")
var nSectors = flag.Int("sectors", 2048, "Number of sectors in volume")
var bytesPerSector = flag.Int("bpsect", 512, "Bytes per sector")
var volumeName = flag.String("vol", "WorkDisk", "Volume name of the image")
var outputName = flag.String("out", "sdimage.bin", "Output file containing filesystem image")
var impName = flag.String("import", "imgs", "Directory containing files to import into image.")

func main() {
	flag.Parse()

	fout, err := os.Create(*outputName)
	if err != nil {
		log.Fatal(err)
	}
	defer fout.Close()

	f := &ImageFile{}
	f.outputWriter = fout
	f.nbytes = *nSectors * *bytesPerSector
	f.bytes = make([]byte, f.nbytes)
	f.dptr = *startDIR * *bytesPerSector
	for i := 0; i < f.nbytes; i++ {
		f.bytes[i] = 0xCC
	}

	if *nDIR < 1 {
		log.Fatal("Number of directory sectors must at least be 1.")
	}
	endDIR := *startDIR + *nDIR - 1
	f.bind("$DIR", *startDIR, endDIR, 1)
	f.bind(*volumeName, 0, 0, 2)

	startIPL, endIPL := f.place("sys/$IPL")
	startSYS, endSYS := f.place("sys/$SYS")

	fmt.Println("startIPL ", startIPL, "endIPL ", endIPL)
	fmt.Println("startSYS ", startSYS, "endSYS ", endSYS)
	fmt.Println("startDIR ", *startDIR, "endDIR ", endDIR)

	f.wptr = *bytesPerSector * (endDIR+1)
	filesAndDirs, err := ioutil.ReadDir(*impName)
	if err != nil {
		log.Fatal(err)
	}
	for _, fi := range filesAndDirs {
		if fi.IsDir() {
			continue
		}
		fmt.Println(*impName + "/" + fi.Name())
		start, end := f.place(*impName + "/" + fi.Name())
		fmt.Println("  start ", start, "end ", end)
	}

	r := bytes.NewReader(f.bytes)
	io.Copy(f.outputWriter, r)
}

func (f *ImageFile) place(filename string) (int, int) {
	sectorStart := f.wptr / 512

	file, err := os.Open(filename)
	if err != nil {
		log.Fatal(err)
	}
	defer file.Close()

	size, err := file.Seek(0, os.SEEK_END)
	if err != nil {
		log.Fatal(err)
	}
	file.Seek(0, os.SEEK_SET)
	size = (size + 511) & -512

	bs, err := ioutil.ReadAll(file)
	if err != nil {
		log.Fatal(err)
	}

	copy(f.bytes[f.wptr:], bs)
	f.wptr = f.wptr + int(size)

	sectorEnd := (f.wptr - 1) / 512

	basename := path.Base(filename)
	f.bind(basename, sectorStart, sectorEnd, 1)
	return sectorStart, sectorEnd
}

func (f *ImageFile) bind(filename string, start, end, kind int) {
	if len(filename) > 47 {
		filename = filename[0:46]
	}
	f.bytes[f.dptr] = byte(len(filename))
	copy(f.bytes[f.dptr+1:], filename)
	f.bytes[f.dptr+48] = byte(kind)
	f.bytes[f.dptr+49] = 0
	f.bytes[f.dptr+50] = byte(start & 255)
	f.bytes[f.dptr+51] = byte((start >> 8) & 255)
	f.bytes[f.dptr+52] = byte(end & 255)
	f.bytes[f.dptr+53] = byte((end >> 8) & 255)
	for i := 54; i < 64; i++ {
		f.bytes[f.dptr+i] = 0
	}
	f.dptr = f.dptr + 64
}
