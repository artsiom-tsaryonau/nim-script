#!/usr/bin/env ns

//DEPS requires:jsony

import jsony

type Info = object
  runner: string
  dep: string

echo Info(runner: "ns", dep: "jsony").toJson()
