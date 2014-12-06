#!/bin/sh

cd $(dirname $0)

ruby ../bin/make_ojm.rb -c ../example/book.yml -l swift > OJM.swift

echo > a.swift
cat OJM.swift >> a.swift
cat run_book.swift >> a.swift

xcrun swift -I . -sdk $(xcrun --show-sdk-path --sdk macosx) a.swift

