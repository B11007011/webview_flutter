#!/bin/bash

# Ensure script is run from project root
if [ ! -d "android" ]; then
  echo "Error: Please run this script from the project root directory."
  exit 1
fi

# Check if gradlew exists
if [ ! -f "android/gradlew" ]; then
  echo "Gradle wrapper not found in android directory."
  
  # If gradlew exists in project root, copy it
  if [ -f "gradlew" ]; then
    echo "Found gradlew in project root, copying to android directory..."
    cp gradlew android/
    cp gradlew.bat android/
    
    # Ensure executable
    chmod +x android/gradlew
    echo "Copied gradlew files to android directory."
  else
    echo "No gradlew found in project root either."
    echo "Generating Gradle wrapper files..."
    
    # Generate gradle wrapper files
    cd android
    gradle wrapper
    cd ..
    
    # Ensure executable
    chmod +x android/gradlew
    echo "Generated Gradle wrapper files."
  fi
else
  echo "Gradle wrapper exists in android directory."
  # Ensure it's executable
  chmod +x android/gradlew
fi

# Verify gradle wrapper jar exists
if [ ! -f "android/gradle/wrapper/gradle-wrapper.jar" ]; then
  echo "gradle-wrapper.jar not found."
  
  # Create directories if needed
  mkdir -p android/gradle/wrapper
  
  # Copy gradle-wrapper.jar if it exists in project root
  if [ -f "gradle/wrapper/gradle-wrapper.jar" ]; then
    echo "Copying gradle-wrapper.jar from project root..."
    cp gradle/wrapper/gradle-wrapper.jar android/gradle/wrapper/
    cp gradle/wrapper/gradle-wrapper.properties android/gradle/wrapper/
    echo "Copied gradle wrapper jar files."
  else
    echo "No gradle-wrapper.jar found in project root."
    echo "Please run 'flutter build apk --debug' to generate missing files."
  fi
else
  echo "gradle-wrapper.jar exists."
fi

echo "Done. You should now be able to run the GitHub Actions workflow." 