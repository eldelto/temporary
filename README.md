
# Temporary

A temporary, encrypted file sharing service.

- [Temporary](#temporary)
  - [Introduction](#introduction)
    - [File Upload](#file-upload)
    - [Chunker Implementation](#chunker-implementation)
    - [File Cleanup](#file-cleanup)
  - [Getting Started](#getting-started)
  - [To-Do](#to-do)
  - [Screens](#screens)

## Introduction

Summary of the core functionality used by Temporary.

### File Upload

Temporary uses the following flow to encrypt and upload your files:

1.   Create a random 16 byte UUID and 8 Byte password
2.   Encrypt the filename using AES
3.   Call the backend to create a new chunked file with the given filename
4.   Split the file into chunks (currently 0.25 MB)
5.   For each chunk
     1.   Encode each chunk in Base64 
     2.   Encrypt it using the generated password and AES
     3.   Upload the file to the backend
6.   Commit the file on the backend (mark upload as done)

### Chunker Implementation

Temporary uses [chunker](https://github.com/eldelto/chunker) to deal with
files in chunks.

The Mnesia based implementation can be found in `storable.ex`.

### File Cleanup

Uploaded files are stored in Mnesia for a limited amount of time (currently 3
days).

For the cleanup a scheduled process ([cleanup.ex](https://github.com/eldelto/temporary/blob/master/lib/temporary_server/cleanup.ex)) runs every 5 minutes to check for old files and deletes them.

## Getting Started

```
git clone https://github.com/eldelto/temporary.git

cd temporary 

// Start development server
mix phx.server

// Build Docker image
./docker_build.sh
```

## To-Do

- [x] Implement chunked upload
  - [x] Server
  - [x] Client
- [x] Implement chunked download
  - [x] Server
  - [x] Client
- [x] Prevent download of uncommitted chunked files
- [x] Clean up job for chunked files
- [x] Upload view
  - [x] Progress bar
  - [x] Custom error toasts
  - [x] Counter
  - [x] Copy link
- [x] Download view
  - [x] Counter
  - [x] Download button
  - [x] Custom error toasts
  - [x] File not found page
- [x] Version number
- [x] Use CSS variables
- [x] Add tests
- [ ] Use custom exceptions in error tuple
- [ ] Add type specs
- [ ] Use web worker for encryption?
- [ ] Review encryption

## Screens

![Upload View](https://raw.githubusercontent.com/eldelto/temporary/master/docs/resources/upload-view.png)

![Download View](https://raw.githubusercontent.com/eldelto/temporary/master/docs/resources/download-view.png)
