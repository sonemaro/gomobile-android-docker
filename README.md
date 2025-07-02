# Gomobile Docker Build Environment

A complete Docker-based build environment for creating Android libraries from Go code using Google's `gomobile` tool. This image provides a consistent, reproducible environment for cross-compiling Go applications to Android AAR libraries.

## 🚀 Features

- **Go 1.23.10** with full gomobile support
- **Android SDK** with command-line tools
- **Android NDK 23.1.7779620** (LTS version)
- **Pre-configured gomobile** with all dependencies
- **Clean, isolated build environment**
- **No host system pollution**
- **Reproducible builds across different machines**
- **Support for multiple Android API levels**

## 📋 Prerequisites

- Docker installed on your system
- Go source code that you want to compile for Android

## 🏗️ Building the Image

```bash
# Clone or download the Dockerfile
git clone <your-repo-url>
cd gomobile-docker

# Build the image
docker build -t gomobile:latest .
```

**Build time:** ~5-10 minutes (depending on your internet connection)

## 📱 Supported Android API Levels

| API Level | Android Version | Device Coverage | Recommended For |
|-----------|----------------|-----------------|-----------------|
| **21** | 5.0+ (Lollipop) | ~99% | Maximum compatibility |
| **23** | 6.0+ (Marshmallow) | ~95% | **Recommended for VPN/Network apps** |
| **28** | 9.0+ (Pie) | ~85% | Modern features |
| **31** | 12+ (Snow Cone) | ~70% | Latest Android features |

## 🎯 Quick Start

### 1. Prepare Your Go Code

Create a directory with your Go package:

```bash
mkdir my-android-lib
cd my-android-lib
```

**example.go:**
```go
package mylib

import "fmt"

// Hello returns a greeting message
func Hello(name string) string {
    return fmt.Sprintf("Hello, %s from Android!", name)
}

// Add returns the sum of two integers
func Add(a, b int) int {
    return a + b
}
```

**go.mod:**
```go
module mylib

go 1.23
```

### 2. Build Android Library

```bash
# Basic build (API 21 - maximum compatibility)
docker run --rm -v $(pwd):/module gomobile:latest bind -target=android .

# Recommended build (API 23 - good balance)
docker run --rm -v $(pwd):/module gomobile:latest bind -target=android -androidapi=23 .

# Custom output name
docker run --rm -v $(pwd):/module gomobile:latest bind -target=android -androidapi=23 -o myapp.aar .
```

**Output:** `mylib.aar` and `mylib-sources.jar`

## 📝 Usage Examples

### Example 1: Simple Library

**calculator.go:**
```go
package calculator

// Calculator provides basic math operations
type Calculator struct{}

// NewCalculator creates a new calculator instance
func NewCalculator() *Calculator {
    return &Calculator{}
}

// Add two numbers
func (c *Calculator) Add(a, b float64) float64 {
    return a + b
}

// Multiply two numbers
func (c *Calculator) Multiply(a, b float64) float64 {
    return a * b
}
```

**Build:**
```bash
docker run --rm -v $(pwd):/module gomobile:latest bind -target=android -androidapi=23 .
```

### Example 2: Network/VPN Library

**vpnclient.go:**
```go
package vpnclient

import (
    "context"
    "log"
    "time"
)

// VPNClient represents a VPN connection
type VPNClient struct {
    serverURL string
    username  string
    isRunning bool
    ctx       context.Context
    cancel    context.CancelFunc
}

// NewVPNClient creates a new VPN client
func NewVPNClient(serverURL, username, password string) *VPNClient {
    ctx, cancel := context.WithCancel(context.Background())
    return &VPNClient{
        serverURL: serverURL,
        username:  username,
        ctx:       ctx,
        cancel:    cancel,
    }
}

// Connect establishes VPN connection
func (v *VPNClient) Connect() error {
    log.Printf("Connecting to %s as %s", v.serverURL, v.username)
    v.isRunning = true
    // Add your VPN logic here
    return nil
}

// Disconnect closes VPN connection
func (v *VPNClient) Disconnect() error {
    v.isRunning = false
    v.cancel()
    return nil
}

// IsConnected returns connection status
func (v *VPNClient) IsConnected() bool {
    return v.isRunning
}

// GetStats returns connection statistics
func (v *VPNClient) GetStats() string {
    if v.isRunning {
        return "Connected to " + v.serverURL
    }
    return "Disconnected"
}
```

**go.mod:**
```go
module vpnclient

go 1.23

require (
    github.com/gorilla/websocket v1.5.1
)
```

**Build with dependencies:**
```bash
# Build for modern Android (API 23+)
docker run --rm -v $(pwd):/module --entrypoint=/bin/bash gomobile:latest -c "
    cd /module && 
    go mod tidy &&
    go get golang.org/x/mobile/bind && 
    gomobile bind -target=android -androidapi=23 .
"
```

### Example 3: Interactive Development

**For development and testing:**
```bash
# Get an interactive shell
docker run --rm -it -v $(pwd):/module --entrypoint=/bin/bash gomobile:latest

# Inside the container:
go mod tidy                    # Update dependencies
go build .                     # Test compilation
go test .                      # Run tests
gomobile bind -target=android . # Build AAR
```

### Example 4: Build Script

**build-android.sh:**
```bash
#!/bin/bash

# Configuration
API_LEVEL=${1:-23}
OUTPUT_NAME=${2:-$(basename "$PWD")}

echo "🏗️  Building Android library: $OUTPUT_NAME"
echo "📱 Target API Level: $API_LEVEL"

# Check if go.mod exists
if [ ! -f "go.mod" ]; then
    echo "❌ No go.mod found. Please run 'go mod init <module-name>' first."
    exit 1
fi

# Build with gomobile
docker run --rm -v $(pwd):/module --entrypoint=/bin/bash gomobile:latest -c "
    set -e
    cd /module
    echo '📦 Installing dependencies...'
    go mod tidy
    go get golang.org/x/mobile/bind
    
    echo '🔨 Building Android library...'
    gomobile bind -target=android -androidapi=$API_LEVEL -o $OUTPUT_NAME.aar .
    
    echo '✅ Build successful!'
    ls -la *.aar *.jar
"

if [ $? -eq 0 ]; then
    echo "📱 Android library ready: $OUTPUT_NAME.aar"
    echo "📋 Import this file into your Android Studio project"
else
    echo "❌ Build failed!"
    exit 1
fi
```

**Usage:**
```bash
chmod +x build-android.sh

# Build with default settings (API 23)
./build-android.sh

# Build for specific API level
./build-android.sh 28

# Build with custom name
./build-android.sh 23 mycustomlib
```

## 🔧 Advanced Usage

### Multi-Platform Builds

```bash
# Android only
docker run --rm -v $(pwd):/module gomobile:latest bind -target=android .

# iOS only (if needed)
docker run --rm -v $(pwd):/module gomobile:latest bind -target=ios .

# Both platforms
docker run --rm -v $(pwd):/module gomobile:latest bind -target=android,ios .
```

### Custom Build Flags

```bash
# Debug build
docker run --rm -v $(pwd):/module gomobile:latest bind -target=android -ldflags="-s -w" .

# With build tags
docker run --rm -v $(pwd):/module gomobile:latest bind -target=android -tags="production" .

# Verbose output
docker run --rm -v $(pwd):/module gomobile:latest bind -target=android -v .
```

### Docker Compose Setup

**docker-compose.yml:**
```yaml
version: '3.8'

services:
  gomobile:
    build: .
    image: gomobile:latest
    volumes:
      - ./src:/module
      - ./output:/output
    working_dir: /module
    command: bind -target=android -androidapi=23 .

  gomobile-dev:
    build: .
    image: gomobile:latest
    volumes:
      - ./src:/module
    working_dir: /module
    entrypoint: /bin/bash
    stdin_open: true
    tty: true
```

**Usage:**
```bash
# Build
docker-compose run --rm gomobile

# Development shell
docker-compose run --rm gomobile-dev
```

## 📱 Using in Android Studio

### 1. Import the AAR

1. Copy `yourlib.aar` to `app/libs/` in your Android project
2. Add to `app/build.gradle`:

```gradle
android {
    compileSdk 34
    
    defaultConfig {
        minSdk 23  // Match your gomobile API level
        targetSdk 34
    }
}

dependencies {
    implementation files('libs/yourlib.aar')
}
```

### 2. Use in Your Android App

**MainActivity.java:**
```java
import yourlib.Yourlib;  // Generated package
import yourlib.Calculator;

public class MainActivity extends AppCompatActivity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        
        // Use your Go library
        Calculator calc = Yourlib.newCalculator();
        double result = calc.add(5.0, 3.0);
        
        Log.d("GoMobile", "Result: " + result);
    }
}
```

**MainActivity.kt (Kotlin):**
```kotlin
import yourlib.Yourlib

class MainActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        
        // Use your Go library
        val calc = Yourlib.newCalculator()
        val result = calc.add(5.0, 3.0)
        
        Log.d("GoMobile", "Result: $result")
    }
}
```

## 🐛 Troubleshooting

### Common Issues

**1. "no Go package in golang.org/x/mobile/bind"**
```bash
# Solution: Add the dependency manually
docker run --rm -v $(pwd):/module --entrypoint=/bin/bash gomobile:latest -c "
    cd /module && go get golang.org/x/mobile/bind && gomobile bind -target=android .
"
```

**2. "imported and not used" errors**
```bash
# Remove unused imports from your Go code
# Go is strict about unused imports
```

**3. "unsupported API version" with NDK**
```bash
# Use supported API levels (19-34)
gomobile bind -target=android -androidapi=23 .
```

**4. Build fails with CGO errors**
```bash
# Ensure your Go code doesn't use unsupported CGO features
# Gomobile has limitations with CGO
```

### Debug Mode

```bash
# Get detailed build information
docker run --rm -v $(pwd):/module gomobile:latest bind -target=android -v -x .

# Check gomobile environment
docker run --rm gomobile:latest env
```

## 📊 Performance Notes

- **Build time:** 30 seconds - 2 minutes (depends on code complexity)
- **Output size:** Typically 1-10 MB for basic libraries
- **Supported architectures:** ARM64, ARMv7, x86, x86_64
- **Go features:** Most standard library, limited CGO support

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### Development Setup

```bash
git clone <your-repo-url>
cd gomobile-docker

# Test the build
docker build -t gomobile:test .

# Run tests
docker run --rm gomobile:test version
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Related Links

- [GoMobile Documentation](https://pkg.go.dev/golang.org/x/mobile)
- [Android API Levels](https://developer.android.com/guide/topics/manifest/uses-sdk-element#ApiLevels)
- [Go Mobile Wiki](https://github.com/golang/mobile/wiki)



---

**Happy mobile development!** 🚀
