# -*- coding: utf-8 -*-
"""AFK_Econ.ipynb

Automatically generated by Colaboratory.

Original file is located at
    https://colab.research.google.com/drive/1x6IoijCL_Io84QUK3mG7GepktkOeX1YP
"""

import pandas as pd
import urllib.request, json 
import numpy as np

# json imports
with urllib.request.urlopen("https://raw.githubusercontent.com/jdendres/economy/main/fos_chapter_df.json5") as url:
    fos_ch = pd.DataFrame(json.loads(url.read().decode()))

with urllib.request.urlopen("https://raw.githubusercontent.com/jdendres/economy/main/fos_player_df.json5") as url:
    fos_p = pd.DataFrame(json.loads(url.read().decode()))

with urllib.request.urlopen("https://raw.githubusercontent.com/jdendres/economy/main/vip_df.json5") as url:
    vip = pd.DataFrame(json.loads(url.read().decode()))

with urllib.request.urlopen("https://raw.githubusercontent.com/jdendres/economy/main/idle.json5") as url:
    idle = pd.DataFrame(json.loads(url.read().decode()))

with urllib.request.urlopen("https://raw.githubusercontent.com/jdendres/economy/main/pvp_df.json5") as url:
    pvp = pd.DataFrame(json.loads(url.read().decode()))

with urllib.request.urlopen("https://raw.githubusercontent.com/jdendres/economy/main/guild_df.json5") as url:
    guild = pd.DataFrame(json.loads(url.read().decode()))

# Pandas Frame Styling
pd.set_option('display.max_rows', None)
pd.set_option('display.max_columns', None)
pd.set_option('display.width', None)
pd.options.display.float_format = '{:,.5f}'.format

# ! Variables
PLAYER_LEVEL = '180'
VIP = '15'
CHAPTER = '36'
ARENA_RANK = '1'
WRIZZ_CHESTS = '23'
WRIZZ_GUILD_GOLD = 1080000
WRIZZ_GUILD_COIN = 1158
SOREN_CHESTS = '23'
SOREN_GUILD_GOLD = 1080000
SOREN_GUILD_COIN = 1158
KINGS_TOWER = 670
CELE_HYPO_TOWER = 201
FACTION_TOWER = 451

fos_p = fos_p[PLAYER_LEVEL]
fos_ch = fos_ch[CHAPTER]
idle = idle[CHAPTER]

# New Mechanic
# * T1 Gear Drop
if KINGS_TOWER >= 250:
    T1_DROP = True
    if KINGS_TOWER >= 300:
        if KINGS_TOWER >= 350:
            T1_DROP_BONUS = 2.0
        else: T1_DROP_BONUS = 1.0
    else: T1_DROP_BONUS = 0
else: T1_DROP = False

# * T2 Gear Drop
if FACTION_TOWER >= 200:
    T2_DROP = True
    if FACTION_TOWER >= 240:
        if FACTION_TOWER >= 280:
            T2_DROP_BONUS = 2.0
        else: T2_DROP_BONUS = 1.0
    else: T2_DROP_BONUS = 0
else: T2_DROP = False

# * Invigorating Essence Drop Bonus
if CELE_HYPO_TOWER >= 100:
    if CELE_HYPO_TOWER >= 200:
        if CELE_HYPO_TOWER >= 300:
            idle['invigor'] = idle['invigor'] * (1 + 0.9)
        else: idle['invigor'] = idle['invigor'] * (1 + 0.6)
    else: idle['invigor'] = idle['invigor'] * (1 + 0.3)

# ? SUBSCRIPTION?
SUBSCRIPTION = True

sub = {
    'gold': 0,  # Base AFK Reward Gold
    'guild_coin': 0,  # Bonus Guild Coins
    'maze_coin': 0,  # Bonus Maze Coins
}
if SUBSCRIPTION:
    sub['gold'] = 0.1
    sub['guild_coin'] = 0.1
    sub['maze_coin'] = 0.1

# ! Guild Hunt
if int(VIP) >= 6: guild_challenge = 3
else: guild_challenge = 2

GUILD_BOSS = {
    'gold': guild[WRIZZ_CHESTS]['gold']* guild_challenge + WRIZZ_GUILD_GOLD + (guild[SOREN_CHESTS]['gold'] * guild_challenge + SOREN_GUILD_GOLD) / 2,
    'guild_coin': guild[WRIZZ_CHESTS]['guild_coin'] * (1 + sub['guild_coin'] + fos_ch['guild_coin']) * guild_challenge + WRIZZ_GUILD_COIN + (guild[SOREN_CHESTS]['guild_coin'] * (1 + sub['guild_coin'] + fos_ch['guild_coin']) * guild_challenge + SOREN_GUILD_COIN) / 2
}
guild_daily = pd.Series(GUILD_BOSS)

# ! Fabled
# ? Is your Guild in Fabled?
FABLED = True
if FABLED: FABLED = 100  # Diamonds
else: FABLED = 0

# ! Challenger Tournament - TODO
challenger = 399 * 24

# ! Store
# ? Buy Dust with Gold?
dStore = True
if dStore: dStore = [2225000, 500]
else: dStore = [0, 0]

# ? Buy Poe with Gold?
pStore = True
if dStore: pStore = [1125000, 250]
else: pStore = [0, 0]

# ? Buy Dust chest with diamonds?
dChestStore = False
if dChestStore: dChestStore = 1
else: dChestStore = 0

# ? Refreshes?
rStore = 2

STORE = {
    'gold': -(1 + rStore) * (dStore[0] + pStore[0]),
    'dust': (1 + rStore) * dStore[1],
    'poe': (1 + rStore) * pStore[1],
    'diamond': -rStore * (100 + 300 * dChestStore),
    'dust_hours': (1 + rStore) * 24 * dChestStore,
}
store_daily = pd.Series(STORE)

# ! Fast Rewards
# ? Number of Fast Rewards?
FAST = 7  # Drop-down input
FAST_COST = {
    1: -0,
    2: -50,
    3: -130,
    4: -230,
    5: -330,
    6: -530,
    7: -830,
    8: -1230,
}
FAST_COST = FAST_COST[FAST]

# ! Twisted Realm - Fabled: Twisted Realm Reward Selection
twisted_normal = {
    'twisted': 380,
    'poe': 1290
}
twisted_double = {
    'twisted': 760,
    'poe': 2580
}
twisted_normal = pd.Series(twisted_normal)
twisted_double = pd.Series(twisted_double)
twisted_daily = ((twisted_normal * 8 + twisted_double * 4) / 24)

# Daily quests
daily_quests = {
    'gold_hours': 2,
    'dust_hours': 2,
    'arena': 2,  # Tickets
    'diamond': 100,
    'scroll': 1,
    'blue': 5
}
CHAPTER = int(CHAPTER)
if CHAPTER > 16: daily_quests['diamond'] = 150
if CHAPTER > 20: daily_quests['exp_hours'] = 2
if CHAPTER > 23: daily_quests['gold_hours'] = 4

weekly_quests = {
    'gold_hours': 16,
    'diamond': 400,
    'scroll': 3,
    'blue': 60,
    'purple': 10,
    'reset': 1,
}
if CHAPTER > 22: weekly_quests['twisted'] = 50
if CHAPTER > 23: weekly_quests['poe'] = 500
if CHAPTER > 28: weekly_quests['silver_e'] = 20
if CHAPTER > 29: weekly_quests['gold_e'] = 10
if CHAPTER > 30: weekly_quests['red_e'] = 5
CHAPTER = str(CHAPTER)

daily_quests = pd.Series(daily_quests)
weekly_quests = pd.Series(weekly_quests)

quests_daily = (daily_quests + weekly_quests / 7).fillna(weekly_quests / 7).fillna(daily_quests)

# ! PVP
ARENA_TICKET = {  # Per Ticket
    'gold': 90000 * 0.495,
    'dust': 10 * 0.495,
    'pit': 0.01
}
PIT_MASTER = {
    'dust': 500 * 0.2,
    'blue': 60 * 0.2,
    'purple': 10 * 0.3,
    'diamond': 150 * 0.15 + 300 * 0.12 + 3000 * 0.03
}
ARENA_TICKET = pd.Series(ARENA_TICKET)
PIT_MASTER = pd.Series(PIT_MASTER)

ARENA_DAILY = ARENA_TICKET * (vip[VIP]['arena'] + daily_quests['arena'])
PIT = PIT_MASTER * ARENA_DAILY['pit']
ARENA_DAILY = (ARENA_DAILY + PIT).fillna(ARENA_DAILY).fillna(PIT).drop('pit')
ARENA_DAILY['diamond'] = ARENA_DAILY['diamond'] + (13 * pvp[ARENA_RANK]['daily'] + pvp[ARENA_RANK]['biweekly']) / 14

# ! Oak Inn
OAK = {
    'gold': 1500000 * 3/4,
    'dust': 150 * 3/4,
    'diamond': 100 * 3/4,
    'blue': 30 * 3/4
}
OAK = pd.Series(OAK)

# ! Monthly Cards - TODO: CARD LEVEL SELECTION
# ? NORMAL CARD?
NORMAL_CARD = True

# ? DELUXE CARD?
DELUXE_CARD = True

# ? TWISTED OR POE?
DELUXE_TWISTED = True

MONTHLY = {  # Monthly Card : Daily
    'gold_hours': 6,
    'exp_hours': 6,
    'dust_hours': 6,
    'diamond': 100
}
MONTHLY_DELUXE = {  # Monthly Deluxe Card : Daily
    'red_e': 4,
    'diamond': 600
}
if DELUXE_TWISTED: MONTHLY_DELUXE['twisted'] = 40
else: MONTHLY_DELUXE['poe'] = 300

MONTHLY = pd.Series(MONTHLY)
MONTHLY_DELUXE = pd.Series(MONTHLY_DELUXE)
CARDS = (MONTHLY + MONTHLY_DELUXE).fillna(MONTHLY).fillna(MONTHLY_DELUXE)

# Merchant Resources
# NORMAL CARD?
NORMAL_CARD = True

# DELUXE CARD?
DELUXE_CARD = True

# TWISTED OR POE?
DELUXE_TWISTED = True
DELUXE_POE = False

MONTHLY = {  # Monthly Card : Daily
    'gold_hours': 6,
    'exp_hours': 6,
    'dust_hours': 6,
    'diamond': 100
}
MONTHLY_DELUXE = {  # Monthly Card : Daily
    'red_e': 4,
    'twisted': 0,  # [A]
    'poe': 0,  # [B]
    'diamond': 600
}
if DELUXE_TWISTED: MONTHLY_DELUXE['twisted'] = 40
else: MONTHLY_DELUXE['poe'] = 300

MONTHLY = pd.Series(MONTHLY)
MONTHLY_DELUXE = pd.Series(MONTHLY_DELUXE)
CARDS = (MONTHLY + MONTHLY_DELUXE).fillna(MONTHLY).fillna(MONTHLY_DELUXE)

# ! Maze - TODO: Arcane vs. Dismal Selection
index = ['dust2', 'exp2', 'gold2', 'gold6']
maze_normal = {
    0: pd.Series([25, 40, 38, 22], index=index),
    1: pd.Series([11, 43, 38, 22], index=index),
    2: pd.Series([11, 43, 45, 14], index=index),
    3: pd.Series([31, 27, 52, 12], index=index),
    4: pd.Series([16, 37, 48, 12], index=index),
    5: pd.Series([25, 29, 54, 12], index=index),
    6: pd.Series([36, 23, 52, 16], index=index),  # Ensign
    7: pd.Series([20, 40, 46, 14], index=index),
    8: pd.Series([18, 32, 60, 12], index=index),
    9: pd.Series([23, 22, 63, 16], index=index),
    10: pd.Series([44, 27, 47, 20], index=index)  # Ensign
}
maze_normal = pd.DataFrame.from_dict(maze_normal)
maze = {
    'gold_hours': (maze_normal.loc['gold2'] * 2 + maze_normal.loc['gold6'] * 6).mean(),  # Hours
    'exp_hours': (maze_normal.loc['exp2'] * 2).mean(),  # Hours
    'dust_hours': (maze_normal.loc['dust2'] * 2).mean(),  # Hours
    'gold': 3 * 8 * 95000 * (1 + vip.loc['maze_gold']),  # Flat Gold
    'exp': 3 * 8 * 133250,  # Flat EXP
    'maze_coin': (6 * 400 + 3 * 600 + 700) * (1 + vip.loc['maze_coin'] + sub['maze_coin']),
    'diamond': 50 + 100 + 200,
    'guild_coin': 1000,
    'glad_coin': 3333
}
maze = pd.DataFrame.from_dict(maze)
maze_daily = (maze.loc[VIP] * 8 + 2 * maze.loc[VIP] * 4) / 24

# ! Idle Rewards

value = {
    "diamond": 1,
    "gold": (500 * 12.5 / idle['dust']) / 2225000,
    "exp": 8 / idle['exp'],
    "dust": 12.5 / idle['dust'],
    "gold_hours": ((500 * 12.5 / idle['dust']) / 2225000) * idle['gold'],
    "exp_hours": 8,
    "dust_hours": 12.5,
    "poe": 0.675,
    "twisted": 6.75,
    "silver_e": 10080000 * (500 * 12.5 / idle['dust']) / 2225000 / 30,
    "gold_e": 10920000 * (500 * 12.5 / idle['dust']) / 2225000 / 20,
    "red_e": 135,
    "dura": 100000 * 500 * 12.5 / idle['dust'] / 2250000,
    "class": 9000 * 0.675 / 400,
    "mythic": (31.450 / 58.926) * 0.9148 * 6000 * 0.675 / 2,  # Random Mythic
    "t1": (33.879 / 40.875) * 0.9148 * 6000 * 0.675 / 2,
    "t2": 0.9148 * 6000 * 0.675 / 2,
    "t3": 9000 * 0.675 / 2,
    "invigor": 0.24,
    "blue": 2.6,
    "purple": 31.2,
    "scroll": 2.6 * 60 * 1.5,
    "faction": 2.6 * 60 * 1.5 * 1.2,
    "t1_g": 0,
    "t2_g": 0
}
value = pd.Series(value)

hourly = idle.copy('deep')
hourly['gold'] = hourly['gold'] * (1 + vip.loc['gold'][VIP] + fos_p['gold'] + sub['gold']) + fos_ch['gold'] / 24 + hourly['dura'] * 100000
hourly['exp'] = hourly['exp'] * (1 + vip.loc['exp'][VIP] + fos_p['exp']) + fos_ch['exp'] / 24
hourly['dust'] = hourly['dust'] * (1 + fos_p['dust']) + fos_ch['dust'] / 24
hourly['mythic'] = hourly['mythic'] * (1 + fos_ch['mythic'])
hourly['t2'] = hourly['t2'] * (1 + fos_ch['t2'])
hourly['t3'] = (1 + fos_ch['t3']) / 336
fast_rewards = (2 * hourly.copy('deep')).drop(["t1_g", "t2_g", "mythic", "t2", "t3", "dura"])
print(fast_rewards)
print((fast_rewards * value).dropna().sum())
# print(fast_rewards)
# print((fast_rewards * value).dropna())
# print((fast_rewards * value).dropna().sum())
idle_daily = hourly.copy('deep') * 24

# ! Misty Valley
MISTY = pd.Series(dtype=int)

# ? CHOICE ONE [CHAPTER 17]
m0GOLD = False  # 288 GOLD HOURS
m0EXP = False  # 96 EXP HOURS
m0DUST = True  # 96 EXP HOURS

if m0GOLD: MISTY['gold_hours'] = 288
elif m0EXP: MISTY['exp_hours'] = 96
else: MISTY['dust_hours'] = 96

# ? CHOICE TWO [CHAPTER 17]
m1DIAMOND = False  # 1000 DIAMOND
m1GUILD_COIN = False  # 30,000 GUILD COINS
m1TWISTED = True  # 400 TWISTED ESSENCE

if m1DIAMOND: MISTY['diamond'] = 1000
elif m1GUILD_COIN: MISTY['guild_coin'] = 30000
else: MISTY['twisted'] = 400

# ? CHOICE THREE [CHAPTER 17]
m2PURPLE = True  # 60 PURPLE SHARDS
m2BLUE = False  # 720 BLUE SHARDS

if m2PURPLE: MISTY['purple'] = 60
else: MISTY['blue'] = 720

# ? CHOICE FOUR [CHAPTER 19]
m3PURPLE = False  # 60 PURPLE SHARDS
m3SCROLL = False  # 5 SCROLLS
m3POE = True  # 1000 POE COINS

if m3PURPLE: MISTY['purple'] = MISTY.get('purple', default=0) + 60
elif m3SCROLL: MISTY['scroll'] = 5
else: MISTY['poe'] = 1000

# ? CHOICE FIVE [CHAPTER 21]
m4SILVER_E = False  # 40 SILVER EMBLEMS
m4GOLD_E = False  # 20 GOLD EMBLEMS
m4RED_E = True  # 10 RED EMBLEMS
m4POE = False  # 1000 POE COINS

if m4SILVER_E: MISTY['silver_e'] = 40
elif m4GOLD_E: MISTY['gold_e'] = 20
elif m4RED_E: MISTY['red_e'] = 10
else: MISTY['poe'] = MISTY.get('poe', default=0) + 1000

# ? CHOICE SIX [CHAPTER 23]
m5T1 = False  # T1
m5T2 = False  # T2
m5T3 = True  # T3
m5POE = False  # 1000 POE COINS

if m5T1: MISTY['t1'] = 1
elif m5T2: MISTY['t2'] = 1
elif m5T3: MISTY['t3'] = 1
else: MISTY['poe'] = MISTY.get('poe', default=0) + 1000

# ? CHOICE SEVEN [CHAPTER 25]
m6SILVER_E = False  # 40 SILVER EMBLEMS
m6GOLD_E = False  # 20 GOLD EMBLEMS
m6RED_E = True  # 10 RED EMBLEMS
m6POE = False  # 1000 POE COINS

if m6SILVER_E: MISTY['silver_e'] = MISTY.get('silver_e', default=0) + 40
elif m6GOLD_E: MISTY['gold_e'] = MISTY.get('gold_e', default=0) + 20
elif m6RED_E: MISTY['red_e'] = MISTY.get('red_e', default=0) + 10
else: MISTY['poe'] = MISTY.get('poe', default=0) + 1000

# ? CHOICE EIGHT [CHAPTER 27]
m7PURPLE = False  # 60 PURPLE SHARDS
m7SCROLL = False  # 5 SCROLLS
m7POE = True  # 1000 POE COINS

if m7PURPLE: MISTY['purple'] = MISTY.get('purple', default=0) + 60
elif m7SCROLL: MISTY['scroll'] = MISTY.get('scroll', default=0) + 5
else: MISTY['poe'] = MISTY.get('poe', default=0) + 1000

# ? CHOICE TEN [CHAPTER 31]
m8SILVER_E = False  # 40 SILVER EMBLEMS
m8GOLD_E = False  # 20 GOLD EMBLEMS
m8RED_E = True  # 10 RED EMBLEMS
m8POE = False  # 1000 POE COINS

if m8SILVER_E: MISTY['silver_e'] = MISTY.get('silver_e', default=0) + 40
elif m8GOLD_E: MISTY['gold_e'] = MISTY.get('gold_e', default=0) + 20
elif m8RED_E: MISTY['red_e'] = MISTY.get('red_e', default=0) + 10
else: MISTY['poe'] = MISTY.get('poe', default=0) + 1000

MISTY['gold'] = MISTY.get('gold', default=0) + 7 * 1000000
MISTY['blue'] = MISTY.get('blue', default=0) + 10 * 120
MISTY['purple'] = MISTY.get('purple', default=0) + 10 * 18
MISTY['poe'] = MISTY.get('poe', default=0) + 30 * 450
MISTY['dust_hours'] = MISTY.get('dust_hours', default=0) + 7 * 4 * 8
MISTY['exp_hours'] = MISTY.get('exp_hours', default=0) + 6 * 24
misty_daily = MISTY.copy('deep') / 30

# ! Bounty Board TODO: Bounty Board Level and Strategy Selection
bounty_normal = {
    8: {
        'dust': 501 + 248 + 99,
        'gold': 1000 * (102 + 13 + 4),
        'diamond': 111 + 17 + 6 - 1.8 * 50,
        'blue': 17 + 4 + 2
    },
    9: {
        'dust': 509 + 327 + 131,
        'gold': 1000 * (103 + 13 + 4),
        'diamond': 147 + 22 + 8 - 2.3 * 50,
        'blue': 17 + 5 + 2
    },
    10: {
        'dust': 512 + 410 + 164,
        'gold': 1000 * (103 + 13 + 4),
        'diamond': 185 + 27 + 10 - 2.8 * 50,
        'blue': 17 + 7 + 3
    }
}
bounty_double = {
    8: {
        'dust': 480 + 1003 + 401,
        'gold': 1000 * 8,
        'diamond': 451 + 67 + 25 - 5.7 * 50,
        'blue': 16 + 17 + 7
    },
    9: {
        'dust': 480 + 1175 + 470,
        'gold': 1000 * 8,
        'diamond': 529 + 78 + 29 - 6.3 * 50,
        'blue': 16 + 20 + 8
    },
    10: {
        'dust': 480 + 1346 + 538,
        'gold': 1000 * 8,
        'diamond': 606 + 90 + 34 - 6.8 * 50,
        'blue': 16 + 22 + 9
    }
}
bounty_normal = pd.DataFrame.from_dict(bounty_normal)
bounty_double = pd.DataFrame.from_dict(bounty_double)
bounty = bounty_normal * 16 / 24 + bounty_double * 8 / 24
bounty_daily = bounty[vip[VIP]['bounty']]

daily_total = (idle_daily + bounty_daily).fillna(bounty_daily).fillna(idle_daily)
daily_total = (daily_total + quests_daily).fillna(quests_daily).fillna(daily_total)
daily_total = (daily_total + maze_daily).fillna(maze_daily).fillna(daily_total)
daily_total = (daily_total + fast_rewards * FAST).fillna(fast_rewards * FAST).fillna(daily_total)
daily_total = (daily_total + guild_daily).fillna(guild_daily).fillna(daily_total)
daily_total = (daily_total + OAK).fillna(OAK).fillna(daily_total)
daily_total = (daily_total + twisted_daily).fillna(twisted_daily).fillna(daily_total)
daily_total = (daily_total + ARENA_DAILY).fillna(ARENA_DAILY).fillna(daily_total).drop('arena')
daily_total = (daily_total + misty_daily).fillna(misty_daily).fillna(daily_total)
daily_total = (daily_total + CARDS).fillna(CARDS).fillna(daily_total)
daily_total = (daily_total + store_daily).fillna(store_daily).fillna(daily_total)

daily_total['gold'] += daily_total['gold_hours'] * idle['gold']
daily_total['exp'] += daily_total['exp_hours'] * idle['exp']
daily_total['dust'] += daily_total['dust_hours'] * idle['dust']
daily_total['diamond'] += (FABLED + FAST_COST)
daily_total['glad_coin'] += challenger
daily_total = daily_total.drop(['gold_hours', 'exp_hours', 'dust_hours'])

# ? Sell Dura?
SELL_DURA = True
if SELL_DURA:
    daily_total['gold'] += daily_total['dura'] * 100000
    daily_total = daily_total.drop('dura')

print(daily_total)