.history as $hi
| ($hi.columns | to_entries | map({(.value): .key}) | add) as $idx
| ($idx["TRADEDATE"]) as $d
| ($idx["OPEN"])      as $o
| ($idx["LOW"])       as $l
| ($idx["HIGH"])      as $g
| ($idx["CLOSE"])     as $c
| ($idx["VOLUME"])    as $v
| (["trade_date", "open_price", "low_price", "high_price", "close_price", "volume"] | @csv),
  ($hi.data[]
   | [ .[$d], .[$o], .[$l], .[$g], .[$c], .[$v] ]
   | @csv)
