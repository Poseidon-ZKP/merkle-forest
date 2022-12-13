import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { PoseidonT3__factory, Smt__factory } from "./types";
import { poseidonContract } from "circomlibjs"

async function main(
) {
    const owners = await ethers.getSigners()
    let owner : SignerWithAddress = owners[0]
    console.log("owner : ", owner.address, " balance : ", await owner.getBalance())

    // deploy contract 2/7 : poseidon(2)
    const NINPUT = 2
    const poseidonABI = poseidonContract.generateABI(NINPUT)
    const poseidonBytecode = poseidonContract.createCode(NINPUT)
    const PoseidonLibFactory = new ethers.ContractFactory(poseidonABI, poseidonBytecode, owner)
    const poseidonLib = await PoseidonLibFactory.deploy()
    await poseidonLib.deployed()
    const pt3 = PoseidonT3__factory.connect(poseidonLib.address, owner)
    console.log("pt3.address : " , pt3.address)

    const IncrementalBinaryTreeLibFactory = await ethers.getContractFactory("IncrementalBinaryTree", {
        libraries: {
            PoseidonT3: pt3.address
        }
    })
    const incrementalBinaryTreeLib = await IncrementalBinaryTreeLibFactory.deploy()
    await incrementalBinaryTreeLib.deployed()
    console.log("incrementalBinaryTreeLib.address : " , incrementalBinaryTreeLib.address)


    const ContractFactory = await ethers.getContractFactory("smt", {
      libraries: {
          IncrementalBinaryTree: incrementalBinaryTreeLib.address
      }
    })
    const sc = await (await ContractFactory.deploy()).deployed()
    const s = Smt__factory.connect(sc.address, owner)
    console.log("smt : ", s.address)

    const eas = await (await s.new_eas(2, 3, 0, {gasLimit: 1000000})).wait()
    console.log("eas : ", eas)


}

main()
.then(() => process.exit(0))
.catch(error => {
  console.error(error);
  process.exit(1);
});

