// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >= 0.8.0;

import "@zk-kit/incremental-merkle-tree.sol/IncrementalBinaryTree.sol";

struct EG {
    uint gurantee;
    uint maxTreeNum;
    mapping(uint256 => IncrementalTreeData) merkleTree;
    uint16 treeNum;
    uint256 zeroValue;
    mapping(uint256 => uint16) member2index;
}

contract smt {
    using IncrementalBinaryTree for IncrementalTreeData;

    event GroupCreated(uint256 indexed groupId, uint256 gurantee, uint256 maxTreeNum);
    
    mapping(uint256 => EG) eg;

    uint public GROUP_ID;

    function _createTree(
        uint256 groupId
    ) internal virtual {
        require(eg[groupId].treeNum < eg[groupId].maxTreeNum, "Group Full!!");
        uint merkleTreeDepth = eg[groupId].gurantee;
        uint zeroValue = eg[groupId].zeroValue;
        eg[groupId].merkleTree[eg[GROUP_ID].treeNum + 1].init(merkleTreeDepth, zeroValue);
        eg[groupId].treeNum++;
    }

    function createGroup(
        uint gurantee,      // privacy level
        uint maxTreeNum,          // group size
        uint zeroValue
    ) public returns(uint) {
        GROUP_ID ++;
        eg[GROUP_ID].gurantee = gurantee;
        eg[GROUP_ID].maxTreeNum = maxTreeNum;
        eg[GROUP_ID].zeroValue = zeroValue;
        eg[GROUP_ID].treeNum = 0;
        _createTree(GROUP_ID);
        emit GroupCreated(GROUP_ID, gurantee, maxTreeNum);
        return GROUP_ID;
    }

    function insert(
        uint256 groupId,
        uint256 identity
    ) public {


        // insert to current tree
        uint16 treeId = eg[groupId].treeNum;
        eg[groupId].merkleTree[treeId].insert(identity);
        uint index = treeId * (2 ** eg[groupId].gurantee) + eg[groupId].merkleTree[treeId].numberOfLeaves + 1;
        eg[groupId].member2index[identity] = index;

        // if tree full
        if (index % (2 ** eg[groupId].gurantee) == 0) {
            // left subtree as seprate merkle tree
            IncrementalTreeData memory left_tree = IncrementalTreeData({
                depth : eg[groupId].gurantee,
                root : eg[groupId].merkleTree[treeId].lastSubtrees[eg[groupId].merkleTree[treeId].root],
                numberOfLeaves : 2 ** eg[groupId].gurantee,
                zeroes : eg[groupId].merkleTree[treeId].zeroes,
                lastSubtrees : eg[groupId].merkleTree[treeId].lastSubtrees
            });

            eg[groupId].merkleTree[treeId] = left_tree;

            // create new tree
            _createTree(GROUP_ID);

            // TODO :  right subtree combin with a new tree to be last tree

        }

    }

    // TODO : IBT verify is private, so using remove for check contains
    // check identity in the tree. (if last tree, gurantee double proof?)
    function contains(
        uint256 groupId,
        uint256 identity,
        uint256[] calldata proofSiblings,
        uint8[] calldata proofPathIndices
    ) public {
        uint index = eg[groupId].member2index[identity];
        require(index != 0, "not in group!!");
        //eg[groupId].merkleTree[treeId].verify(identity, proofSiblings, proofPathIndices);
    }

    function remove(
        uint256 groupId,
        uint256 identity,
        uint256[] calldata proofSiblings,
        uint8[] calldata proofPathIndices
    ) public {
        uint treeId = eg[groupId].member2tree[identity];
        require(treeId != 0, "not in group!!");
        eg[groupId].merkleTree[treeId].remove(identity, proofSiblings, proofPathIndices);
        delete eg[groupId].member2tree[identity];
    }

    function enlargeGroup(
        uint groupId,
        uint size
    ) public {  // TODO : admin only
        eg[groupId].maxTreeNum = size - eg[groupId].gurantee;
    }

    function downsizeGroup(
        uint groupId,
        uint size
    ) public {  // TODO : admin only
        require(eg[groupId].treeNum <= 2 ** (size - eg[groupId].gurantee));
        eg[groupId].maxTreeNum = size - eg[groupId].gurantee;
    }


    function migrate(
        IncrementalTreeData storage merkleTree,
        uint groupId
    ) internal {
        // merkle tree --> group

        // add items in lookup table for each member
    }
}