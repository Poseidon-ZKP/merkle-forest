// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >= 0.8.0;

import "@zk-kit/incremental-merkle-tree.sol/IncrementalBinaryTree.sol";

struct EAS {
    uint H;
    uint K;
}

contract smt {
    using IncrementalBinaryTree for IncrementalTreeData;

    event GroupCreated(uint256 indexed groupId, uint256 merkleTreeDepth, uint256 zeroValue);

    mapping(uint256 => IncrementalTreeData) internal merkleTree;
    
    mapping(uint256 => IncrementalTreeData) internal eas;

    function _createGroup(
        uint256 groupId,
        uint256 merkleTreeDepth,
        uint256 zeroValue
    ) internal virtual {

        merkleTree[groupId].init(merkleTreeDepth, zeroValue);

        emit GroupCreated(groupId, merkleTreeDepth, zeroValue);
    }

    function new_eas(
        uint h,
        uint k
    ) public {

    }

    function insert() public {

    }

    function proof() public {

    }

}