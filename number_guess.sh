#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

echo "Enter your username:"
read USERNAME

IFS="|" read GAMES_PLAYED BEST_GAME USER_ID <<< "$($PSQL "SELECT COUNT(game_id), MIN(tries), user_id FROM games RIGHT JOIN users USING(user_id) WHERE name = '$USERNAME' GROUP BY user_id")"

if [[ $GAMES_PLAYED -gt 0 ]]
then
  echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
else
  echo "Welcome, $USERNAME! It looks like this is your first time here."
  if [[ -z $USER_ID ]]
  then
    USER_ID="$($PSQL "INSERT INTO users(name) VALUES('$USERNAME') RETURNING user_id" -q)"
  fi
fi

SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))
TRIES=0

echo "Guess the secret number between 1 and 1000:"
while :
do
  ((TRIES++))
  read GUESS
  if [[ ! $GUESS =~ ^[0-9]+$ ]]
  then
    echo "That is not an integer, guess again:"
  elif [[ $GUESS -gt $SECRET_NUMBER ]]
  then
    echo "It's lower than that, guess again:"
  elif [[ $GUESS -lt $SECRET_NUMBER ]]
  then
    echo "It's higher than that, guess again:"
  else
    echo "You guessed it in $TRIES tries. The secret number was $SECRET_NUMBER. Nice job!"
    if [[ "$($PSQL "INSERT INTO games(user_id, tries, secret_number) VALUES($USER_ID, $TRIES, $SECRET_NUMBER)")" != "INSERT 0 1" ]]
    then
      echo "ERROR: game was not saved in the database"
      exit 1
    fi
    break
  fi
done
