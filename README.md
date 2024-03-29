# ZK-Friendly Elastic Anonymous Group for Semaphore and More 

We present EAS (ZK-Friendly Elastic Anonymous Group) based on a novel data structure - Merkle Forest. EAS can scale semaphore group to billions of users without increasing the proving time and the proving key size. EAS's core idea is the seperation of group size and anonymity guarantee. With EAS, semaphore protocl could achieve:
1. Elastic (possibly unlimited) group size without increasing proving key size and prover time.
2. Elastic anonymity guarantee that allows the client to make the prover time / anonymity guarantee trade-off.

## Background
[Semaphore](https://semaphore.appliedzkp.org/) is ZKP-powered protocol that allows users to:
* Prove their membership of a group 
* Send signals on a particular topic as a member of a group
without revealing their identity. At the core of this protocol lies the following [circuit](https://semaphore.appliedzkp.org/docs/technical-reference/circuits)
![](https://github.com/semaphore-protocol/semaphore/raw/main/packages/circuits/scheme.png)

The first two private inputs, siblings and path indices, form a path in a Merkle tree, which represents the group whose leaves are the identity commitments of its members. The [Merkle tree verifier](https://github.com/semaphore-protocol/semaphore/blob/main/packages/circuits/tree.circom) outputs the root of the Merkle tree, while checking that the siblings and path indices describe a valid path from the identity commitment leaf to the root. Then the contract compares this root to the existing one. 

## Terminology
* [identity](https://semaphore.appliedzkp.org/docs/guides/identities): a triple consisting of a trapdoor, a nullifier and a commitment. The commitment is computed from the trapdoor and nullifier and is inserted as a leaf in the groups it belongs to.
* Group: In the Semaphore protocol, a Merkle tree. In our proposal, a Merkle forest. 
* Anonymity Guarantee: a security parameter defined by the size of the anonymity set. In the Semaphore protocol above, it is the capacity of the Merkle tree. For a merkle tree with depth $g$, the Merkle tree can store $2^g$ leaves, so the exposure probability, achieved when the group reaches its maximum capacity, is $1/2^g$.
* Max group size. Max number of members a group can host. In the Semaphore protocol, this is the number of leaves the Merkle tree can store.
* EG: Elastic Group, whose size grows dynamically.

## Motivation
In the Semaphore example above, groups are modelled by binary incremental Merkle trees with fixed-size depth (anonymity guarantee). The native way to prove group membership, as explained above, is to verify a Merkle path in a zk-circuit, which means this circuit depends on the tree depth. 

Suppose the below scenarios:
1. Group is almost full. In order to enlarge the group, user would have to create a new group, and ask every member to rejoin. 
2. User want to create a group, but can't decide the guarantee yet, as it might grow  infinitely as bussiness growth. Now the only choice is using an evaluated maximum possible guarantee, and have to enlarge when reach capacity limit. In this case, even at the beginning, when there are few members, we still have to generate full Merkle path proofs, resulting in non-efficent cost for both prover and on-chain verifier, and also have larger trust setup cost, For reference, a guarantee 20 trust setup takes 2 hours on Macbook Pro and produces more than 1G key file.
3. multi user operate concurrently on the group, say, user A already in group, and try to prove membership, while at the same time, another user B try to join the group. if B's join transaction complete firstly (on-chain merkle tree updated), then A's membership prove transaction will fail, as still using old merkle path proof. 

As a conclusion: Group with underline single fixed-size Merkle tree, cann't adjust capacity dynamically, and could be conccurency competition , thus could not fulfill the variety real life user cases for group memebership, even with more cost.


## The solution: Elastic Anonymous Group using Merkle Forest

### Elastic Size 

We define elastic anonymous groups (EAG) with $G(g)$, where $g$ is the depth of each merkle tree and $2^g$ is the default anonymity guarantee. Comparing with a fixed size merkle tree, EAG has a default anonymity guarantee but has no size limit. 

> Note: user can choose to boost up anonymity guarantee using the elastic anonymity guarantee technique introduced in [Next section](#elastic-anonymity-guarantee)

```mermaid
    flowchart LR;
        title[Figure 1. Merkle Forest]
        style single-MT fill:#FBFCFC
        style Merkle-Forest fill:#FBFCFC
        style Lookup-Table fill:#FBFCFC
        style MT1 fill:#FBFCFC
        style MT2 fill:#FBFCFC
        subgraph single-MT
            R((Root))-->C1234 & C5678;
            C1234((C1-4)) --> C12((C12)) & C34((C34));
            C5678((C5-8)) --> C56((C56)) & C78((C78));
            C12-->L1(1) & L2(2)
            C34-->L3(3) & L4(4)
            C56-->L5(5) & L6(6)
            C78-->L7(7)
        end

        subgraph Merkle-Forest
            subgraph Lookup-Table
                LT1(1..4)
                LT5(5..8)
            end
            LT1 -.-> FC1234;
            LT5 -.-> FC5678;

            subgraph MT1
                FC1234((R1-4)) --> FC12((C12)) & FC34((C34));
                FC12-->FL1(1) & FL2(2)
                FC34-->FL3(3) & FL4(4)
            end

            subgraph MT2
                FC5678((R5-8)) --> FC56((C56)) & FC78((C78));
                FC56-->FL5(5) & FL6(6)
                FC78-->FL7(7)
            end
        end

        single-MT -.-> Merkle-Forest

```

With the new elastic group design. the original huge [Merkle tree membership circuit](https://github.com/semaphore-protocol/semaphore/blob/main/packages/circuits/tree.circom) can be reduced to
* a smaller Merkle tree membership circuit, which out=puts a root
* find the output root in a look-up table

### Elastic Anonymity Guarantee

this actually provide "elastic gurantee", suppose the follow cases:
1. user provide the "treeId" of elastic group, and merkle proof of that tree, get a minium grantee.
2. user join a tree which have less leaves, which means it might loss privacy, then user could "merge" its original tree and another full-size tree to be a new tree, and provide membership in the new tree. As an example in Figure 2, if member 4 want to prove membership with anonymity grantee 2, then it can merge serveal trees to make the total members is more than 2**2 in new tree, here merge tree 2 and 3, and provide the merkle proof of new tree.  
3. user might want higher anonymity gurantee, by "merge" all the trees. user decide the gurantee they want. Figure 2 given an example of merge 4 trees in group.

```mermaid
    flowchart TD;
        title[<u>Figure 2. Merge Tree </u>]
        style Merkle-Forest fill:#FBFCFC
        style Merge fill:#FBFCFC
        style MT1 fill:#FBFCFC
        style MT2 fill:#FBFCFC
        style MT3 fill:#FBFCFC
        style MT4 fill:#FBFCFC

        subgraph Merkle-Forest

            subgraph MT1
                R1 --> C1L & C1R;
                C1L-->1LL(2) & 1LR(5)
                C1R-->1RL(ZERO) & 1RR(ZERO)
            end

            subgraph MT2
                R2 --> C2L & C2R;
                C2L-->2LL(1) & 2LR(3)
                C2R-->2RL(7) & 2RR(ZERO)
            end

            subgraph MT3
                R3 --> C3L & C3R;
                C3L-->3LL(4) & 3LR(ZERO)
                C3R-->3RL(ZERO) & 3RR(ZERO)
            end

            subgraph MT4
                R4 --> C4L & C4R;
                C4L-->4LL(2) & 4LR(6)
                C4R-->4RL(ZERO) & 4RR(ZERO)
            end

        end

        subgraph Merge
            ROOT
        end
        ROOT -.-> R2 & R3;


```


The "merge" demands varies between different user case, suppose two kinds of privacy vote case
1. privacy vote only after all user have joined and group freezed.
2. privacy vote happens simultanously as new member join the group.

In the 2nd user case, concurrency competion could happen. for example, when user A vote and user B join the same group at the same time, and the join 1st complete modify merkle tree on-chain, while vote still using old merkle path, result in on-chain verify fail. It could possible be resolved by centralized cordinator, like relayer, in some specific user cases， but not all user case. A native methology is required for reduce concurency competion.

So here, we proposal a hash-based random-member-join strategy, that is, select a random group to join, in this way, simulatanously prove and join activity will most probably operate on different group, thus almost avoid concurrency competition. Figure 3 show an example of random-memeber-join merkle forest.

```mermaid
    flowchart TD;
        title[<u>Figure 3. Merge Tree </u>]
        style Merkle-Forest fill:#FBFCFC
        style Lookup-Table fill:#FBFCFC
        style MT1 fill:#FBFCFC
        style MT2 fill:#FBFCFC
        style MT3 fill:#FBFCFC
        style MT4 fill:#FBFCFC

        subgraph Merkle-Forest

            subgraph Lookup-Table
                LT1(1)
                LT2(2)
                LT3(3)
                LT4(4)
                LT5(5)
                LT6(6)
                LT7(7)
                LT8(8)
            end
                LT2 & LT5 -.-> R1;
                LT1 & LT3 & LT7 -.-> R2;
                LT4 -.-> R3;
                LT2 & LT6 -.-> R4;

            subgraph MT1
                R1 --> C1L & C1R;
                C1L-->1LL(2) & 1LR(5)
                C1R-->1RL(ZERO) & 1RR(ZERO)
            end

            subgraph MT2
                R2 --> C2L & C2R;
                C2L-->2LL(1) & 2LR(3)
                C2R-->2RL(7) & 2RR(ZERO)
            end

            subgraph MT3
                R3 --> C3L & C3R;
                C3L-->3LL(4) & 3LR(ZERO)
                C3R-->3RL(ZERO) & 3RR(ZERO)
            end

            subgraph MT4
                R4 --> C4L & C4R;
                C4L-->4LL(2) & 4LR(6)
                C4R-->4RL(ZERO) & 4RR(ZERO)
            end

        end
```


The random-member-join strategy require more "merge" for anonymity-gruantee prove, because of each tree might be sparse in the number of leaves, and need caculate a list of trees to be merged.  it actually bring unneed burden of the 1st user case, who has no concurrency demands. We can simply apply a "sequential-member-join" strategy instead, for this case, Figure 1 give an example, member always join current tree until it's full. 

## Conclude

We propose elastic group, with default infinite capacity, which can also be enlarge/downsize dynamically. The underline merkle forest using smaller Merkle tree as basic unit, take the benefit of smaller proof circuits, faster prover, Lighter trusted setup cost. Another benefit of merkle forest， is natively reslove the concurenccy competetion probablity. Finally we propose elastic gurantee, there will no any gurantee lost in elastic group.

## Specification

### Semaphore Compatible

"Merkle Forest" is based on the Merkle tree membership circuit, which means no circuit changes are needed, the existing Semaphore circuit and corresponding sdk still work.

An onchain lookup table is introduced to map members to the corresponding Merkle tree.



### Create Elastic Group  

```shell
    function createGroup(
        uint guarantee,
        uint number_of_trees,
        uint zeroValue)
```

Creates a new elastic group, with user-provided anonymity guarantee and number of trees. For example, if the user sets the anonymity guarantee to be 10 and the number of trees size to be 4, then each Merkle tree in this forest has $2^{10} = 1024$ members, which means this EAS has 1/1024 anonymity. This EG can have maximum $2^{10}*4 = 4096$ leaves.

We use an [incremental Merkle tree](https://github.com/privacy-scaling-explorations/zk-kit/tree/main/packages/incremental-merkle-tree) which is fully compatible with Semaphore.

### Join Group

```shell
    function insert(
        uint256 groupId,
        uint256 identity)
```

As explained in the analysis above, to prevent member exposure when their Merkle tree is almost empty, we use a double-split strategy. The last tree will only be full when it reaches a double guarantee limit, and then split into 2 full guarantee trees. The right tree after the splitting will be attached on the right to an empty Merkle tree, thus becoming the new double size Merkle tree in the forest.

### Membership Proof

```shell
    function contains(
        uint256 groupId,
        uint256 identity,
        uint256[] calldata proofSiblings,
        uint8[] calldata proofPathIndices)
```

The membership proof interface is exactly the same as Semaphore's, but with smaller Merkle proofs and faster prover time.

```shell
    function verifyProof(
        uint groupId,
        uint[] calldata treeIds,
        uint[8] calldata proof
    )
```

### Leave Group (optional)

```shell
    function remove(
        uint256 groupId,
        uint256 identity,
        uint256[] calldata proofSiblings,
        uint8[] calldata proofPathIndices)
```

Leave Group is exactly the same as Semaphore's.

### Group Guarantee Change

Elastic Group

```shell
    function enlargeGroup(uint groupId, uint size)
    function downsizeGroup(uint groupId, uint size)
```

Increase/decrease group guarantee, group admin operation.
Decrease only succeeds if the group's member number does not exceed the new max size.


### Migrate existing group

Existing semaphore group can be migrated to EAS easily as the first shard. (more details later)

<!-- ### Composable/CP-Snark(optional)

CP-SNARK and -> or ?  -->


## Profile

benchmark for different depth semaphore group with macbook pro(intel) 2019
show that, circuit constraints growth linearly, so as to pk size and prove time.
while trust setup time/ptau size growth Exponentially, which will benefit more from elastic group design.

|Merkle Tree Depth|trust setup time |ptau size|constraints| pk size|prove time|
|  ----  | ----  | ----  | ----  | ----  | ----  |
|10|2.5 min|18M(ptau.14)|6.6K|2.8M|5.5s|
|16|10 min|72M|9K|2.8M|5.5s|
|20|160 min|1.1G|12K|3.3M|6.5s|
|32|unfinished||18K|5.2M||

## [Reference Implementation](./contracts/elasticGroup/elasticGroup.sol)

Fully compatible with Semaphore Interface, minor changes for implement eas.
