# Merkle Forest

## Abstract



## Motivation

Binary Increamental Merkle Tree(MT), With Special Level(Gurantee), is generally used as Group, which contatins identity commitments of group members(Tree leaf).

ZK using merkle path to prove the group membership, so the circuit size is related(linear) to Group Gurantee. 

Server issues exist for the single MT Group:
    1. group size is defined when create,   not support infinicate group.
    2. prover time growth (linear??) with Gurantee.
    3. onchain gas cost increase(linearly) for group operation(insert..)
    4. concurrency competition issue when multi user join the single group
        (1) reorder tx by relay, not native

## Overview
Philosoph is trade-off
    1. Privacy
    2. Efficent (ZK-Prover/On-chain)

We Propose Merkle Forest, using sharding of multi smaller group, instead of single huge group.
    1. decouple the circuit size from Gurantee.
    2. Group Size = 2^Gurantee = 2^H * 2^(G - H) = 2^H * K, K = 2^(G-H)

```mermaid
    graph LR;
        subgraph single-MT
            R((Root))-->C1234 & C5678;
            C1234((C1-4)) --> C12((C12)) & C34((C34));
            C5678((C5-8)) --> C56((C56)) & C78((C78));
            C12-->L1(1) & L2(2)
            C34-->L3(3) & L4(4)
            C56-->L5(5) & L6(6)
            C78-->L7(7) & L8(8)
        end

        subgraph Merkle-Forest
            FC1234((C1-4)) --> FC12((C12)) & FC34((C34));
            FC5678((C5-8)) --> FC56((C56)) & FC78((C78));
            FC12-->FL1(1) & FL2(2)
            FC34-->FL3(3) & FL4(4)
            FC56-->FL5(5) & FL6(6)
            FC78-->FL7(7) & FL8(8)
        end

```





## Specification

### Create Group
create_eas

    depth 20 -> 10, tune.

increamental MT 
sparse MT

### Membership Prove
contain


### Join Group
append

    Dynamic Growth

Join, L-> R
    Hashed :  less shard expose , auto reorgnize.  re-blance. (tree split, no 2 different group)

### Leave Group(optional)

Privacy/Public Leavy

### Composable/CP-Snark(optional)
CP-SNARK and -> or ? 


 ## Reference Implementation
 TODO


# Setup
```shell
nvm use lts/hydrogen
npm install
npx hardhat run scripts/smt.ts
```

# Gas


# TODO
