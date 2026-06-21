#!/bin/bash
fpc -Fu"resources/" -Fu"tests/unit/" -Fu"tools/" -Fu"routes/" -Fu"method/" -Mdelphi -Sh tests/test_rtti3.pas
./tests/test_rtti3
