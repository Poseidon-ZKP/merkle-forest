// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >= 0.8.0;

import "@zk-kit/incremental-merkle-tree.sol/IncrementalBinaryTree.sol";

struct EAS {
    uint H;
    uint K;
    mapping(uint256 => IncrementalTreeData) merkleTree;
    uint treeNum;
    uint256 zeroValue;
    // TODO :  mapping too big?  map[A] = X, map[B] = X <--> map[A op B] = X ?
    mapping(uint256 => uint256) member2tree;
}

contract smt {
    using IncrementalBinaryTree for IncrementalTreeData;

    event GroupCreated(uint256 indexed groupId, uint256 merkleTreeDepth, uint256 gurantee);
    
    mapping(uint256 => EAS) eas;

    uint public GROUP_ID;

    function _createTree(
        uint256 groupId
    ) internal virtual {
        require(eas[groupId].treeNum <= 2**eas[groupId].K, "Group Full!!");
        uint merkleTreeDepth = eas[groupId].H;
        uint zeroValue = eas[groupId].zeroValue;
        eas[groupId].merkleTree[eas[GROUP_ID].treeNum + 1].init(merkleTreeDepth, zeroValue);
        eas[groupId].treeNum++;
    }

    function createGroup(
        uint tree_depth,
        uint gurantee,
        uint256 zeroValue
    ) public returns(uint) {
        GROUP_ID ++;
        eas[GROUP_ID].H = tree_depth;
        eas[GROUP_ID].K = gurantee - tree_depth;
        eas[GROUP_ID].zeroValue = zeroValue;
        eas[GROUP_ID].treeNum = 0;
        _createTree(GROUP_ID);
        emit GroupCreated(GROUP_ID, tree_depth, gurantee);
        return GROUP_ID;
    }

    function insert(
        uint256 groupId,
        uint256 identity
    ) public {
        // decide which tree to join, or new tree, split tree
        // growth strategy : L->R + Split Group
        //              TODO : random insert
        if (eas[groupId].merkleTree[eas[groupId].treeNum].numberOfLeaves >= 2**(eas[groupId].H)) {
            _createTree(GROUP_ID);
        }

        // insert to current tree
        uint treeId = eas[groupId].treeNum;
        eas[groupId].merkleTree[treeId].insert(identity);
        eas[groupId].member2tree[identity] = treeId;
    }

    // TODO : IBT verify is private, so using remove for check contains
    function contains(
        uint256 groupId,
        uint256 identity,
        uint256[] calldata proofSiblings,
        uint8[] calldata proofPathIndices
    ) public {
        uint treeId = eas[groupId].member2tree[identity];
        require(treeId != 0, "not in group!!");
        //eas[groupId].merkleTree[treeId].verify(identity, proofSiblings, proofPathIndices);
    }

    function remove(
        uint256 groupId,
        uint256 identity,
        uint256[] calldata proofSiblings,
        uint8[] calldata proofPathIndices
    ) public {
        uint treeId = eas[groupId].member2tree[identity];
        require(treeId != 0, "not in group!!");
        eas[groupId].merkleTree[treeId].remove(identity, proofSiblings, proofPathIndices);
        delete eas[groupId].member2tree[identity];
    }

    function enlargeGroup(
        uint groupId,
        uint gurantee
    ) public {  // TODO : admin only
        eas[groupId].K = gurantee - eas[groupId].H;
    }

    function downsizeGroup(
        uint groupId,
        uint gurantee
    ) public {  // TODO : admin only
        require(eas[groupId].treeNum <= 2 ** (gurantee - eas[groupId].H));
        eas[groupId].K = gurantee - eas[groupId].H;
    }


    function migrate(
        IncrementalTreeData storage merkleTree,
        uint groupId
    ) internal {
        // merkle tree --> group

        // add items in lookup table for each member
    }
}