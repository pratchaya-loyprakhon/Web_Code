#!/bin/bash

N=20

scores=()
for ((i=0; i<$N; i++)); do
    scores[i]=$((RANDOM % 101))
done

sum=0
for s in "${scores[@]}"; do
    sum=$((sum + s))
done

avg=$(echo "$sum / $N" | bc -l)

var_sum=0
for s in "${scores[@]}"; do
    diff=$(echo "$s - $avg" | bc -l)
    sq=$(echo "$diff * $diff" | bc -l)
    var_sum=$(echo "$var_sum + $sq" | bc -l)
done
var=$(echo "$var_sum / $N" | bc -l)
sd=$(echo "scale=5; sqrt($var)" | bc -l)

printf "sum = %d, avg = %.5f, sd = %.5f\n" "$sum" "$avg" "$sd"

lowerC=$(echo "$avg - $sd" | bc -l)
upperC=$(echo "$avg + $sd" | bc -l)
upperB=$(echo "$avg + 2 * $sd" | bc -l)

i=1
for s in "${scores[@]}"; do
    grade="F"
    if (( $(echo "$s > $lowerC && $s <= $upperC" | bc -l) )); then
        grade="C"
    elif (( $(echo "$s > $upperC && $s <= $upperB" | bc -l) )); then
        grade="B"
    elif (( $(echo "$s > $upperB" | bc -l) )); then
        grade="A"
    fi
    printf "%2d %s\n" "$i" "$grade"
    ((i++))
done
