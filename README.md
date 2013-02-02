ObjCMongoDB is an Objective-C library for BSON and MongoDB based on the [10gen
C driver](https://github.com/mongodb/mongo-c-driver).

## Getting started

Refer to the installation instructions and sample code on the
[wiki](https://github.com/noa--/ObjCMongoDB/wiki):

 -   [Getting started using ObjCMongoDB in your Mac OS project](https://github.com/noa--/ObjCMongoDB/wiki/GettingStarted)
 -   [The basics of using ObjCMongoDB](https://github.com/noa--/ObjCMongoDB/wiki/TheBasics)

## Features

 -   BSON encoding and decoding based on NSCoder's keyed coding scheme. When
     necessary, encoding and decoding can be implemented entirely outside the model classes with help from robust delegate interfaces.
   
 -   Built-in support for arrays, dictionaries, embedded objects, strings,
     numbers, dates, object IDs, and the miscellaneous MongoDB types.

 -   Automatically encodes and decodes Core Data entities. Using the coder's
     delegate interface you can customize the default behavior, or simply implement the alternate behavior it in the entity class.

 -   Aims to feel Cocoa-like, not Mongo-like. For example, method names in
     MongoKeyedPredicate and MongoUpdateRequest are meant to be natural in Cocoa, rather than conform to the underlying Mongo keywords.

## Status

Based on v0.5 of the 10gen C driver. Mostly complete. Tested under OS X 10.6+
with and without ARC. Should work fine under iOS.

Some missing pieces:

 -   Ensure index
 -   More .h documentation
 -   Write concerns
 -   Upgrade to v0.7.1 of the Mongo C driver
 -   Some commands

## License

Sources copyright Paul Melnikow, 10gen, Matthew Gallagher, and other
contributors.

Unless otherwise specified in a source file, sources in this repository are
published under the terms of the Apache License version 2.0, a copy of which is
in this repository as APACHE-2.0.txt.

## Acknowledgements

 -  Originally based on [NuMongoDB](https://github.com/timburks/NuMongoDB) by Tim Burks: Copyright 2010 Neon Design Technology, Inc.
 -  Includes enhancements by [Diederik Hoogenboom](https://github.com/dhoogenb/NuMongoDB) and [Rob Elkin](https://github.com/robelkin/NuMongoDB)
 -  [Official MongoDB C driver](http://github.com/mongodb/mongo-c-driver): Copyright 2009, 2010 10gen Inc.
 -  [OrderedDictionary](http://cocoawithlove.com/2008/12/ordereddictionary-subclassing-cocoa.html) by Matt Gallagher: Copyright 2008 Matt Gallagher