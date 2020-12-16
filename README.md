# Okta Identity Engine Library

**Table of Contents**

<!-- TOC depthFrom:2 depthTo:3 -->
<!-- /TOC -->

## Design Principles

Since the Identity Engine library is new, and built in Swift, there is an opportunity to create a best-in-class experience for developers that can streamline the process, simplify the developer experience, and provide maximum compatability with existing applications.

As a result, a multi-tiered approach will be made to reach the following goals:

* Full Swift and Objective-C support, with "Swifty" and Objective-C naming conventions.
* Traditional Delegation / block-based patterns used in Objective-C.
* Streamlined Combine extension that can leverage Promises and Futures.
* Overridden `description` and `debugDescription` implementations to aid in debugging.
* Unified Logging and Activity Tracing support for simpler crash log reporting.

## Getting Started

## Supported Platforms

### iOS

### macOS

### tvOS _(Aspirational)_

## Install

### Swift Package Manager

Add the following to the `dependencies` attribute defined in your `Package.swift` file. You can select the version using the `majorVersion` and `minor` parameters. For example:

```swift
dependencies: [
    .Package(url: "https://github.com/okta/okta-idx-swift.git", majorVersion: <majorVersion>, minor: <minor>)
]
```

### Cocoapods

Simply add the following line to your `Podfile`:

```ruby
pod 'OktaIdx'
```

Then install it into your project:

```bash
pod install
```

### Carthage

To integrate this SDK into your Xcode project using [Carthage](https://github.com/Carthage/Carthage), specify it in your Cartfile:
```ruby
github "okta/okta-idx-swift"
```

## Usage Guide

## Configuration Reference

## API Reference

## Development

## Known issues
