## Common parameters:
##
##  $era:
##    "sophie"
##    "evie"
##    "jen"
##
##  $composition:
##    { n_bft_hosts:       INT
##    , n_singular_hosts:  INT
##    , n_dense_hosts:     INT
##    }
##
## This specification is interpreted by 'lib-params.sh' as follows:
##
##  1. The chosen node count determines the topology file.
##  2. The topology file determines the BFT/stake pool composition.
##  3. The era and composition determine base genesis/generator parameters.
##  4. The era determines sets of genesis/generator profiles,
##     a set product of which defines _benchmarking profiles_,
##     which are then each extended with era tolerances,
##     yielding _final benchmarking profiles_.
##

def genesis_defaults($era; $compo):
{ common:

  ## Trivia
  { protocol_magic:          42

  ## UTxO & delegation
  , total_balance:           900000000000000
  , pools_balance:           800000000000000
  , delegators:              $compo.n_dense_hosts
  , utxo:                    1000000

  ## Blockchain time & block density
  , active_slots_coeff:      0.05
  , epoch_length:            2200   # Ought to be at least (10 * k / f).
  , parameter_k:             10
  , slot_duration:           1
  , genesis_future_offset:   "3 minutes"

  ## Block size & contents
  , max_block_size:          64000
  , max_tx_size:             16384

  ## Cluster composition
  , dense_pool_density:      1

  ## Ahh, the sweet dear legacy..
  , cole:
    { parameter_k:             2160
    , n_poors:                 128
    , n_delegates:             $compo.n_total
    ## Note, that the delegate count doesnt have to match cluster size.
    , delegate_share:          0.9
    , avvm_entries:            128
    , avvm_entry_balance:      100000000000000
    , secret:                  2718281828
    , slot_duration:           20
    , max_block_size:          2000000
    }
  }

, sophie:
  { decentralisation_param:  0.5
  }

, evie:
  { decentralisation_param:  0.5
  }

, jen:
  { decentralisation_param:  0
  }
} | (.common + .[$era]);

def generator_defaults($era):
{ common:
  { add_tx_size:             100
  , init_cooldown:           45
  , inputs_per_tx:           2
  , outputs_per_tx:          2
  , tx_fee:                  1000000
  , epochs:                  10
  , tps:                     2
  }
} | (.common + (.[$era] // {}));

def node_defaults($era):
{ common:
  { expected_activation_time:      30
  }
} | (.common + (.[$era] // {}));

def derived_genesis_params($era; $compo; $gtor; $gsis; $node):
  (if      $compo.n_hosts > 50 then 20
  else if $compo.n_hosts == 3 then 3
  else 10 end end)                      as $future_offset
|
{ common:
  ({ n_pools: ($compo.n_singular_hosts
             + $compo.n_dense_hosts * $gsis.dense_pool_density)
   , genesis_future_offset: "\($future_offset) minutes"
   } +
   if $gsis.dense_pool_density > 1
   then
   { n_singular_pools:  $compo.n_singular_hosts
   , n_dense_pools:    ($compo.n_dense_hosts
                       * $gsis.dense_pool_density) }
   else
   { n_singular_pools: ($compo.n_singular_hosts
                        + $compo.n_dense_hosts)
   , n_dense_pools:     0 }
   end)
} | (.common + (.[$era] // {}));

def derived_generator_params($era; $compo; $gtor; $gsis; $node):
  ($gsis.epoch_length * $gsis.slot_duration) as $epoch_duration
| ($epoch_duration * $gtor.epochs)           as $duration
|
{ common:
  { era:                     $era
  , tx_count:                ($gtor.tx_count
                              // ($duration * $gtor.tps))
  }
} | (.common + (.[$era] // {}));

def derived_node_params($era; $compo; $gtor; $gsis; $node):
{ common: {}
} | (.common + (.[$era] // {}));

def derived_tolerances($era; $compo; $gtor; $gsis; $node; $tolers):
{ common:
  { finish_patience:
    ## TODO:  fix ugly
    ($gtor.finish_patience // $tolers.finish_patience)
  }
} | (.common + (.[$era] // {}));

def may_attr($attr; $dict; $defdict; $scale; $suf):
  if ($dict[$attr] //
      error("undefined attr: \($attr)"))
     != $defdict[$attr]
  then [($dict[$attr] | . / $scale | tostring) + $suf] else [] end;

def profile_name($compo; $gsis; $gtor; $node):
  ## Genesis
  [ "k\($gsis.n_pools)" ]
  + may_attr("dense_pool_density";
             $gsis; genesis_defaults($era; $compo); 1; "ppn")
  + [ ($gtor.epochs                    | tostring) + "ep"
    , ($gsis.utxo           | . / 1000 | tostring) + "kU"
    , ($gsis.delegators     | . / 1000 | tostring) + "kD"
    , ($gsis.max_block_size | . / 1000 | tostring) + "kbs"
    ]
  + may_attr("tps";
             $gtor; generator_defaults($era); 1; "tps")
  + may_attr("epoch_length";
             $gsis; genesis_defaults($era; $compo); 1; "eplen")
  + may_attr("add_tx_size";
             $gtor; generator_defaults($era); 1; "b")
  + may_attr("inputs_per_tx";
             $gtor; generator_defaults($era); 1; "i")
  + may_attr("outputs_per_tx";
             $gtor; generator_defaults($era); 1; "o")
  | join("-");

def utxo_delegators_density_profiles:
  [ { genesis: { utxo: 2000000, delegators:  500000 } }
  , { genesis: { utxo: 2000000, delegators:  500000, dense_pool_density: 2 } }
  , { genesis: { utxo: 2000000, delegators:  500000 }
    , generator: { tps: 5 } }
  , { genesis: { utxo: 2000000, delegators:  500000 }
    , generator: { tps: 10 } }


  , { genesis: { utxo: 2000000, delegators:  500000 }
    , generator: { epochs:  6 } }

  , { genesis: { utxo: 2000000, delegators:  500000, max_block_size:  128000 }
    , generator: { tps:  16 } }
  , { genesis: { utxo: 2000000, delegators:  500000, max_block_size:  256000 }
    , generator: { tps:  32 } }
  , { genesis: { utxo: 2000000, delegators:  500000, max_block_size:  512000 }
    , generator: { tps:  64 } }
  , { genesis: { utxo: 2000000, delegators:  500000, max_block_size: 1024000 }
    , generator: { tps: 128 } }
  , { genesis: { utxo: 2000000, delegators:  500000, max_block_size: 2048000 }
    , generator: { tps: 256 } }

  , { genesis: { utxo:  4000000, delegators:  1000000 } }
  , { genesis: { utxo:  8000000, delegators:  2000000 } }
  , { genesis: { utxo: 10000000, delegators:  2500000 } }

  , { desc: "#1: baseline for Aurum hard fork, as agreed with Neil"
    , genesis: { utxo:  3000000, delegators:   750000 }
    , generator: { epochs: 4 }
    , node: { extra_config:
              { TestAurumHardForkAtEpoch: 1
              }}}

  , { desc: "#2: baseline + some time"
    , genesis: { utxo:  4500000, delegators:  1000000 }
    , generator: { epochs: 4 }
    , node: { extra_config:
              { TestAurumHardForkAtEpoch: 1
              }}}

  , { desc: "#3: for 1.29 release, below mainnet datasets, but we need comparability"
    , genesis: { utxo: 2000000, delegators:  500000 }
    , generator: { tps: 10, scriptMode: false } }

  , { desc: "#4: for 1.29 release, at mainnet datasets"
    , genesis: { utxo: 3000000, delegators:  750000 }
    , generator: { tps: 10, scriptMode: false } }

  , { desc: "#5: calibration, with ~30 tx/64k-block"
    , genesis: { utxo: 2000000, delegators:  500000 }
    , generator: { add_tx_size: 2000, tps: 10, scriptMode: false } }
];

def generator_profiles:
  [ { generator: {} }
  ];

def node_profiles:
  [ { node: {} }
  ];

def profiles:
  [ utxo_delegators_density_profiles
  , generator_profiles
  , node_profiles
  ]
  | [combinations]
  | map (reduce .[] as $item ({}; . * $item))
  | map (. *
        { node:
          { expected_activation_time:
            (60 * ((.genesis.delegators / 500000)
                   +
                   (.genesis.utxo       / 2000000))
                / 2)
          }
        });

def era_tolerances($era; $genesis):
{ common:
  { cluster_startup_overhead_s:     60
  , start_log_spread_s:             300
  , last_log_spread_s:              120
  , silence_since_last_block_s:     120
  , tx_loss_ratio:                  0.02
  , finish_patience:                42
  , minimum_chain_density:          ($genesis.active_slots_coeff * 0.5)
  }
, sophie:
  { maximum_missed_slots:           0
  }
} | (.common + .[$era]);

def aux_profiles:
[ { name: "smoke-10000"
  , generator: { tx_count: 10000, inputs_per_tx: 1, outputs_per_tx: 1,  tps: 100 }
  , genesis:
    { genesis_future_offset: "3 minutes"
    , utxo:                  1000
    , dense_pool_density:    10
    }
  }
, { name: "smoke-1000"
  , generator: { tx_count: 1000,  inputs_per_tx: 1, outputs_per_tx: 1,  tps: 100
               , init_cooldown: 25, finish_patience: 4 }
  , genesis:
    { genesis_future_offset: "3 minutes"
    , utxo:                  1000
    , dense_pool_density:    10
    }
  }
, { name: "smoke-100"
  , generator: { tx_count: 100,   inputs_per_tx: 1, outputs_per_tx: 1,  tps: 100
               , init_cooldown: 25, finish_patience: 4 }
  , genesis:
    { genesis_future_offset: "3 minutes"
    , utxo:                  1000
    , dense_pool_density:    10
    }
  }
, { name: "smoke-k50"
  , generator: { tx_count: 100,   inputs_per_tx: 1, outputs_per_tx: 1,  tps: 100
               , init_cooldown: 90, finish_patience: 4 }
  , genesis:
    { genesis_future_offset: "20 minutes" }
  }
];