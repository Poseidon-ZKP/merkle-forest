import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { deploy } from "@openzeppelin/hardhat-upgrades/dist/utils";
import { expect } from "chai";
import { randomBytes } from "crypto";
import { ethers } from "hardhat";
import { exit } from "process";
import { DpTables__factory, Evaluator7__factory, Flush1__factory, Flush2__factory, Flush3__factory, NoFlush10__factory, NoFlush11__factory, NoFlush12__factory, NoFlush13__factory, NoFlush14__factory, NoFlush15__factory, NoFlush16__factory, NoFlush17__factory, NoFlush1__factory, NoFlush2__factory, NoFlush3__factory, NoFlush4__factory, NoFlush5__factory, NoFlush6__factory, NoFlush7__factory, NoFlush8__factory, NoFlush9__factory } from "./types";

// Evaluator
// 1. Rank
// 2. Big in Rank


// Note 
// 1. compile long time, do not touch flush/
async function deploy_flushs(
  owner : SignerWithAddress,
  using_previous_deploy : boolean
) {
  
  if (using_previous_deploy) {
    return [
        '0xA1980305533385CA58273e6Bf947956324e39041',
        '0x99993F3DA09cf76d4CbCF43ea7D2977a9792B7BF',
        '0x724bdd89A71e233E4000646eaf83dE60Ca1FAA8d'
    ]

  }
  let flushs = []
  flushs.push((await (new Flush1__factory(owner)).deploy()).address)
  flushs.push((await (new Flush2__factory(owner)).deploy()).address)
  flushs.push((await (new Flush3__factory(owner)).deploy()).address)
  return flushs
}

async function deploy_no_flushs(
  owner : SignerWithAddress,
  using_previous_deploy : boolean
) {
    let noflushs =[]
    if (using_previous_deploy) {
      return [
        '0x07766aD370370af9d2564A2B44f34be626d3E2e0',
        '0xabEc9277CBC275131b61c41081cc5b5a08C267a3',
        '0x91b1bf08A37EB91294FC8dc59b0951A2EEF1522a',
        '0x608242cB19bcBBfeC14CA47A7DA146048d407098',
        '0x0A7C5f090Be105EfAb0Cf6705e4f7135c267A3E9',
        '0x432D0AF948bab85e65D6672de68D20B2cE13E1a6',
        '0xcC9a29f1C7EFF7F21B2ebee2ea5039c7b507f30a',
        '0xA610bE3F3220C932D7215dA9C16f1105F1b278C2',
        '0xDe3fFd98d7030c057b2B75913732d43ec1978408',
        '0xbFF54DEA53D243E35389e3f2C7F9c148b0113104',
        '0xE0837d7477A7b19b19e153750aC263513dA2E5d2',
        '0x9ffA320029C5883852428db23cF5449477a04626',
        '0xA9B7E7Cbe38DB57c35CbCff3F77CB98d28D218e3',
        '0x8F8a52Ee35A15F29c789b7a635aA78bC10628B87',
        '0x968A20D6241BCCaBe710136950876aD1Bf31512f',
        '0x1C254319da64bD459A361B0f4568306DabcCF6E2',
        '0xF3E8A05937d2f02192604b0B59Ed311808662Ff9'
      ]
    }

    noflushs.push((await (new NoFlush1__factory(owner)).deploy()).address)
    noflushs.push((await (new NoFlush2__factory(owner)).deploy()).address)
    noflushs.push((await (new NoFlush3__factory(owner)).deploy()).address)
    noflushs.push((await (new NoFlush4__factory(owner)).deploy()).address)
    noflushs.push((await (new NoFlush5__factory(owner)).deploy()).address)
    noflushs.push((await (new NoFlush6__factory(owner)).deploy()).address)
    noflushs.push((await (new NoFlush7__factory(owner)).deploy()).address)
    noflushs.push((await (new NoFlush8__factory(owner)).deploy()).address)
    noflushs.push((await (new NoFlush9__factory(owner)).deploy()).address)
    noflushs.push((await (new NoFlush10__factory(owner)).deploy()).address)
    noflushs.push((await (new NoFlush11__factory(owner)).deploy()).address)
    noflushs.push((await (new NoFlush12__factory(owner)).deploy()).address)
    noflushs.push((await (new NoFlush13__factory(owner)).deploy()).address)
    noflushs.push((await (new NoFlush14__factory(owner)).deploy()).address)
    noflushs.push((await (new NoFlush15__factory(owner)).deploy()).address)
    noflushs.push((await (new NoFlush16__factory(owner)).deploy()).address)
    noflushs.push((await (new NoFlush17__factory(owner)).deploy()).address)

    return noflushs
}

async function main(
) {
    const owners = await ethers.getSigners()
    let owner : SignerWithAddress = owners[0]
    console.log("owner : ", owner.address, " balance : ", await owner.getBalance())

    const dpTable = await (new DpTables__factory(owner)).deploy()
    console.log("dpTable.address : ", dpTable.address)

    let flushs = await deploy_flushs(owner, process.env.USING_PREDEPLOY_FLUSHS == undefined ? false : true)
    console.log("flushs : ", flushs)

    let noflushs = await deploy_no_flushs(owner, process.env.USING_PREDEPLOY_FLUSHS == undefined ? false : true)
    console.log("noflushs : ", noflushs)

    const eva = await (new Evaluator7__factory(owner)).deploy(
      dpTable.address,
      flushs,
      noflushs,
      {gasLimit : 300000000}
    )
    console.log("eva.address : " , eva.address)

    enum RANK {
      STRAIGHT_FLUSH  = 0,
      FOUR_OF_A_KIND  = 1,
      FULL_HOUSE      = 2,
      FLUSH           = 3,
      STRAIGHT        = 4,
      THREE_OF_A_KIND = 5,
      TWO_PAIR        = 6,
      ONE_PAIR        = 7,
      HIGH_CARD       = 8
    }

    //  Spades "2/3/4/5/6/7/8"
    expect(await eva.handRankV2([0, 4, 8, 12, 16, 20, 24])).eq(RANK.STRAIGHT_FLUSH)
    console.log("flush_gas : ", await eva.estimateGas.handRankV2([0, 4, 8, 12, 16, 20, 24]))

    // Spades "2/3/4/5/6" Hearts"2" Diamonds"2"
    expect(await eva.handRankV2([0, 4, 8, 12, 16, 1, 2])).eq(RANK.STRAIGHT_FLUSH)

    // Spades "2/3/4/5/7" Hearts"2" Diamonds"2"
    expect(await eva.handRankV2([0, 4, 8, 12, 20, 1, 2])).eq(RANK.FLUSH)
    // "Spades 2/2/2", "Spades 3", "Spades4", "SpadesQ", "SpadesK"
    expect(await eva.handRankV2([0, 1, 2, 4, 8, 40, 44])).eq(RANK.FLUSH)

    // "2/2/2/2", "3/3", "4"
    expect(await eva.handRankV2([0, 1, 2, 3, 4, 5, 8])).eq(RANK.FOUR_OF_A_KIND)

    // "2/2/2", "3/3", "4/4"
    expect(await eva.handRankV2([0, 1, 2, 4, 5, 8, 9])).eq(RANK.FULL_HOUSE)

    // "2/3/4/5/6", "A/A"
    expect(await eva.handRankV2([0, 5, 10, 14, 18, 48, 49])).eq(RANK.STRAIGHT)

    // "2/2/2", "3", "4", "Q", "K"
    expect(await eva.handRankV2([0, 1, 2, 4, 8, 41, 44])).eq(RANK.THREE_OF_A_KIND)

    // "2/2", "3/3", "4", "Q", "K"
    expect(await eva.handRankV2([0, 1, 4, 5, 8, 41, 44])).eq(RANK.TWO_PAIR)

    // "2/2", "3", "4", "5", "Q", "K"
    expect(await eva.handRankV2([0, 1, 4, 8, 14, 41, 44])).eq(RANK.ONE_PAIR)

    // "2", "3", "4", "5", "J",  "Q", "K"
    expect(await eva.handRankV2([0, 4, 8, 14, 39, 41, 44])).eq(RANK.HIGH_CARD)
    console.log("unflush gas : ", await eva.estimateGas.handRankV2([0, 4, 8, 14, 39, 41, 44]))

}

main()
.then(() => process.exit(0))
.catch(error => {
  console.error(error);
  process.exit(1);
});

