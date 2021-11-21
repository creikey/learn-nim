import os
import std/tables

let params = os.commandLineParams()
if params.len() < 1 or params.len() > 2:
    echo "Usage: bf.nim [brainfuck program file] [optional input to program file]"
    quit(QuitFailure)

proc getText(fileName: string): string =
  try:
    readFile(fileName)
  except Exception as e:
   echo "Could not read file: ", e.msg
   quit(QuitFailure)
        

let text = getText(params[0])
var inputText: string = ""
if params.len() == 2:
    inputText = getText(params[1])

var rightMemory: seq[uint8] = @[0'u8]
var leftMemory: seq[uint8] = @[] # for negative memory pointer
var instructionIndex = 0
var inputIndex = 0
var memoryIndex = 0

proc curMem(): var uint8 =
    if memoryIndex >= 0:
        result = rightMemory[memoryIndex]
    else:
        result = leftMemory[-1 * memoryIndex - 1]

proc fixMemory(): void =
    while memoryIndex >= 0 and memoryIndex >= rightMemory.len():
        rightMemory.add(0'u8)
    while memoryIndex < 0 and -memoryIndex > leftMemory.len():
        leftMemory.add(0'u8)

var openBraceMap = initTable[int, int]() # open brace location, close brace location
var closeBraceMap = initTable[int, int]() # close brace location, open brace location

var openBraceStack: seq[int] = @[]

for idx, t in text:
    if t == '[':
        openBraceStack.add(idx)
    elif t == ']':
        let correspondingOpenBrace = openBraceStack.pop()
        openBraceMap[correspondingOpenBrace] = idx
        closeBraceMap[idx] = correspondingOpenBrace
if openBraceStack.len() > 0:
    echo "Unclosed open brace: ", openBraceStack[openBraceStack.len() - 1]
    quit(1)

var steps = 0
while instructionIndex < text.len():
    let cur = text[instructionIndex] 
    case cur
    of '+':
        curMem() += 1
    of '-':
        curMem() -= 1
    of '.':
        stdout.write char(curMem())
    of ',':
        if inputIndex < inputText.len():
            curMem() = uint8(inputText[inputIndex])
            inputIndex += 1
        else:
            echo "\nRan out of input to give the brainfuck program"
            quit(QuitSuccess)
    of '>':
        memoryIndex += 1
        fixMemory()
    of '<':
        memoryIndex -= 1
        fixMemory()
    of '[':
        if curMem() == 0:
            instructionIndex = openBraceMap[instructionIndex]
    of ']':
        if curMem() != 0:
            instructionIndex = closeBraceMap[instructionIndex]
    else:
        discard
    
    steps += 1
    instructionIndex += 1

echo "\nTotal steps: ", steps