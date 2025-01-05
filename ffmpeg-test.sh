#!/bin/zsh

STREAM_HOST="http://rp.risk-mermaid.ts.net:8000/"
CLIENT_INSTANCES=3;

# Install dependencies
# brew install coreutils;  # install gdate

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting ${CLIENT_INSTANCES} streaming instances...${NC}";
for i in $(seq 1 $CLIENT_INSTANCES); do
    SEED=$(gdate +%N)
    DURATION=$(awk -v min=5 -v max=15 -v seed=$SEED 'BEGIN{srand(seed + PROCINFO["pid"]); print int(min+rand()*(max-min+1))}')
    ffmpeg -i $STREAM_HOST -t $DURATION -progress pipe:1 -loglevel debug -f null - 2>&1 | grep --line-buffered "Statistics: .* bytes read" | sed 's/.*AVIOContext @ [^ ]* //' | awk -v duration=$DURATION -v yellow=$YELLOW -v nc=$NC '{print yellow "Duration: " duration " seconds, " $0 nc}' &
done
wait

echo -e "${GREEN}The streaming test is done.${NC}";
