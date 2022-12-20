// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >= 0.8.0;

import {PoseidonT3} from "@zk-kit/incremental-merkle-tree.sol/Hashes.sol";
import "@zk-kit/incremental-merkle-tree.sol/IncrementalBinaryTree.sol";

struct EG {
    uint gurantee;
    uint maxTreeNum;
    mapping(uint => IncrementalTreeData) merkleTree;
    uint treeNum;
    uint zeroValue;
    mapping(uint => uint) member2tree;
}

interface IVerifier {
    function verifyProof(
        uint[2] memory a,
        uint[2][2] memory b,
        uint[2] memory c,
        uint[1] memory input
    ) external view;
}

contract elasticGroup {
    using IncrementalBinaryTree for IncrementalTreeData;

    event GroupCreated(uint indexed groupId, uint gurantee, uint maxTreeNum);
    mapping(uint => EG) eg;
    uint public GROUP_ID;
    mapping(uint => IVerifier) internal verifiers;

    struct Verifier {
        address contractAddress;
        uint merkleTreeDepth;
    }
    constructor(Verifier[] memory _verifiers) {
        for (uint8 i = 0; i < _verifiers.length; ) {
            verifiers[_verifiers[i].merkleTreeDepth] = IVerifier(_verifiers[i].contractAddress);

            unchecked {
                ++i;
            }
        }
    }


    function createTree(
        uint groupId
    ) internal virtual {
        require(eg[groupId].treeNum < eg[groupId].maxTreeNum, "Group Full!!");
        eg[groupId].merkleTree[eg[GROUP_ID].treeNum + 1].init(
            eg[groupId].gurantee,
            eg[groupId].zeroValue
        );
        eg[groupId].treeNum++;
    }

    function createGroup(
        uint gurantee,
        uint maxTreeNum,
        uint zeroValue
    ) public returns(uint) {
        GROUP_ID ++;
        eg[GROUP_ID].gurantee = gurantee;
        eg[GROUP_ID].maxTreeNum = maxTreeNum;
        eg[GROUP_ID].zeroValue = zeroValue;
        eg[GROUP_ID].treeNum = 0;
        createTree(GROUP_ID);
        emit GroupCreated(GROUP_ID, gurantee, maxTreeNum);
        return GROUP_ID;
    }

    function insert(
        uint groupId,
        uint identity
    ) public {
        if (eg[groupId].merkleTree[eg[groupId].treeNum].numberOfLeaves == 2 ** eg[groupId].gurantee) {
            // current tree full, create new tree
            createTree(groupId);
        }

        uint treeId = eg[groupId].treeNum;
        eg[groupId].merkleTree[treeId].insert(identity);
        eg[groupId].member2tree[identity] = treeId;
    }

    // TODO : IBT verify is private function, so using remove for check contains
    // check identity in the tree. (if last tree, gurantee double proof?)
    function contains(
        uint groupId,
        uint identity,
        uint[] calldata proofSiblings,
        uint8[] calldata proofPathIndices
    ) public {
        uint treeId = eg[groupId].member2tree[identity];
        require(treeId != 0, "not in group!!");
        //eg[groupId].merkleTree[treeId].verify(identity, proofSiblings, proofPathIndices);
    }

    // prove membership by combile merkle trees, provide elastic gurantee
    function verifyProof(
        uint groupId,
        uint[] calldata treeIds,
        uint[8] calldata proof
    ) external view returns (bool) {
        uint merkleTreeDepth;
        uint merkleTreeRoot;

        if (treeIds.length == 1) {
            merkleTreeDepth = eg[groupId].gurantee;
            merkleTreeRoot = eg[groupId].merkleTree[treeIds[0]].root;
        } else if (treeIds.length == 2) {
            merkleTreeDepth = eg[groupId].gurantee + 1;

            merkleTreeRoot = PoseidonT3.poseidon([
                eg[groupId].merkleTree[treeIds[0]].root, 
                eg[groupId].merkleTree[treeIds[1]].root 
            ]);
        } else {
            // TODO :  merge more trees to provide higher gurantee.
        }


        IVerifier verifier = verifiers[merkleTreeDepth];
        verifier.verifyProof(
            [proof[0], proof[1]],
            [[proof[2], proof[3]], [proof[4], proof[5]]],
            [proof[6], proof[7]],
            [merkleTreeRoot]
        );
        return true;
    }

    function remove(
        uint groupId,
        uint identity,
        uint[] calldata proofSiblings,
        uint8[] calldata proofPathIndices
    ) public {
        uint treeId = eg[groupId].member2tree[identity];
        require(treeId != 0, "not in group!!");
        eg[groupId].merkleTree[treeId].remove(identity, proofSiblings, proofPathIndices);
        delete eg[groupId].member2tree[identity];
    }

    function enlarge(
        uint groupId,
        uint size
    ) public {
        eg[groupId].maxTreeNum = size - eg[groupId].gurantee;
    }

    function downsize(
        uint groupId,
        uint maxTreeNum
    ) public {
        require(eg[groupId].treeNum < maxTreeNum);
        eg[groupId].maxTreeNum = maxTreeNum;
    }

    function migrate(
        IncrementalTreeData storage merkleTree,
        uint groupId
    ) internal {
        // merkle tree --> group

        // add items in lookup table for each member
    }
}