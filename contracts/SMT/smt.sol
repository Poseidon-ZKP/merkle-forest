// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >= 0.8.0;

import "@zk-kit/incremental-merkle-tree.sol/IncrementalBinaryTree.sol";

struct EAS {
    uint H;
    uint K;
    mapping(uint256 => IncrementalTreeData) merkleTree;
    uint treeNum;
    uint256 zeroValue;
    mapping(uint256 => uint256) member2tree;
}

contract smt {
    using IncrementalBinaryTree for IncrementalTreeData;

    event GroupCreated(uint256 indexed groupId, uint256 merkleTreeDepth, uint256 gurantee);
    
    mapping(uint256 => EAS) eas;

    uint public GROUP_ID;

    function _createTree(
        uint256 groupId,
        uint256 treeId
    ) internal virtual {
        uint merkleTreeDepth = eas[groupId].H;
        uint zeroValue = eas[groupId].zeroValue;
        eas[groupId].merkleTree[treeId].init(merkleTreeDepth, zeroValue);
    }

    function new_eas(
        uint h,
        uint gurantee,
        uint256 zeroValue
    ) public returns(uint) {
        GROUP_ID ++;
        eas[GROUP_ID].H = h;
        eas[GROUP_ID].K = gurantee - h;
        eas[GROUP_ID].zeroValue = zeroValue;
        _createTree(GROUP_ID, 1);
        emit GroupCreated(GROUP_ID, h, gurantee);
        return GROUP_ID;
    }

    function insert(
        uint256 groupId,
        uint256 identity
    ) public {
        // decide which tree to join, or new tree, split tree
        // growth strategy : L->R + Split Group
        //              TODO : random insert
        uint treeId = eas[groupId].treeNum + 1;
        if (eas[groupId].merkleTree[treeId].numberOfLeaves >= 2^(eas[groupId].H)) {
            _createTree(GROUP_ID, treeId);
        } else {
            // insert to current tree
            eas[groupId].merkleTree[treeId].insert(identity);
        }

        eas[groupId].treeNum++;
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
}