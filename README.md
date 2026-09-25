# Bible Viewer

## About

This project lets everyone freely read and study the Bible.
My goal is to make a fast, easy-to-use platform for all people to
learn about the Bible.

Please enjoy. God Bless.

## Get the Project

Open your terminal (or Command Prompt if you are on Windows), and type:

```bash
git clone --recursive https://github.com/Vigilantie/Bible-Viewer
cd Bible_Viewer
```

## Build

### UNIX/Mac/Linux

The Makefile is for convenience, so running make, or the appropriate CMake command, will produce the same results. Build with the GUI (Currently Apple only support for other platforms coming soon).

```bash
make
```

or build the library

```bash
make library
```

### Windows

If you have GNU make, you can run make as well, run this.

```bash
mkdir -p build
cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
cmake --build .
```

## Using the Library

Read [Docs](./docs/API.md) for API details.

## Dependencies

CMake
C/C++ Compiler

## License

This project is licensed under the GNU GPLv3.
Please read LICENSE.txt for the full license.
