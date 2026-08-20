#!/usr/bin/env ns

//DEPS requires:jsony

import jsony
import os

type Info = object
  runner: string
  version: int

let cwd = getEnv("NS_CWD", getCurrentDir())
let configPath = cwd / "config.json"

if fileExists(configPath):
  echo readFile(configPath)
else:
  echo "No config.json found at ", configPath, ". Creating sample JSON object..."
  echo Info(runner: "ns", version: 1).toJson()
