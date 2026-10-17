extends Node

# Menu signals
signal new_game
signal credits

# Game signals
signal round_start
signal round_end(earnings: int)

signal pause
signal unpause

signal junk_collected(junk: JunkResource)
signal junk_deposited(junk: JunkResource)

signal damage_taken(amount: int)
