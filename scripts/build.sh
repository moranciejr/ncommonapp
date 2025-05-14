#!/bin/bash

# Check if environment variables are set
if [ -z "$STREAM_API_KEY" ] || [ -z "$STREAM_SECRET_KEY" ] || [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_ANON_KEY" ]; then
    echo "Error: Required environment variables are not set"
    echo "Please set the following variables:"
    echo "- STREAM_API_KEY"
    echo "- STREAM_SECRET_KEY"
    echo "- SUPABASE_URL"
    echo "- SUPABASE_ANON_KEY"
    exit 1
fi

# Build the app with environment variables
flutter build web \
    --dart-define=STREAM_API_KEY=$STREAM_API_KEY \
    --dart-define=SUPABASE_URL=$SUPABASE_URL \
    --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY \
    --release

echo "Build completed successfully!" 