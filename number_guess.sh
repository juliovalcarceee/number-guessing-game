#!/bin/bash

PSQL="psql -X --username=freecodecamp --dbname=number_guess -t --no-align -q -c"

# Número secreto entre 1 y 1000
SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))

echo "Enter your username:"
read USERNAME

# Una sola consulta: id del usuario, partidas jugadas y mejor partida
USER_INFO=$($PSQL "SELECT u.user_id, COUNT(g.game_id), COALESCE(MIN(g.guesses), 0) FROM users u LEFT JOIN games g ON g.user_id = u.user_id WHERE u.username = '$USERNAME' GROUP BY u.user_id")

if [[ -z $USER_INFO ]]
then
  # Usuario nuevo
  echo "Welcome, $USERNAME! It looks like this is your first time here."
  USER_ID=$($PSQL "INSERT INTO users(username) VALUES('$USERNAME') RETURNING user_id")
else
  # Usuario que ya ha jugado
  IFS="|" read USER_ID GAMES_PLAYED BEST_GAME <<< "$USER_INFO"
  echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

NUMBER_OF_GUESSES=0
echo "Guess the secret number between 1 and 1000:"
read GUESS || exit

while true
do
  if [[ ! $GUESS =~ ^[0-9]+$ ]]
  then
    echo "That is not an integer, guess again:"
  else
    NUMBER_OF_GUESSES=$(( NUMBER_OF_GUESSES + 1 ))
    if (( 10#$GUESS == SECRET_NUMBER ))
    then
      break
    elif (( 10#$GUESS > SECRET_NUMBER ))
    then
      echo "It's lower than that, guess again:"
    else
      echo "It's higher than that, guess again:"
    fi
  fi
  read GUESS || exit
done

$PSQL "INSERT INTO games(user_id, guesses) VALUES($USER_ID, $NUMBER_OF_GUESSES)" > /dev/null

echo "You guessed it in $NUMBER_OF_GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!"
