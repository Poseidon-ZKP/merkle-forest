import '@typechain/hardhat'
import "@nomiclabs/hardhat-waffle"
import "@nomiclabs/hardhat-ethers";
import "@openzeppelin/hardhat-upgrades"
import '@nomiclabs/hardhat-etherscan'
import "hardhat-contract-sizer"

require('dotenv').config()

const customAccounts = [
    `0x828a065aa2818619cb9a5435ce9e7d95fdd3e6dd89fc5fcd4dd4a37346a54084`, // 0x7A7765Db4733DFe037342A8bCDfAEE83ddE405da
    `0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d`, // 0x70997970c51812dc3a010c7d01b50e0d17dc79c8
    `0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a`, // 0x3c44cdddb6a900fa2b585dd299e03d12fa4293bc
]

let hardhatAccounts = []
customAccounts.forEach(a => {
    hardhatAccounts.push(
        {
            privateKey : a,
            balance : "10000000000000000000000"
        }
  )
});

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    compilers : [
      {
        version: '0.8.12',
        settings: {
            optimizer: {
                enabled: false,
                runs: 1
            }
        }
      }, 
      {
        version: '0.8.4'
      },
      {
        version: '0.5.16'
      }
    ]
  },
  typechain: {
    outDir: 'scripts/types',
    target: 'ethers-v5',
    alwaysGenerateOverloads: false, // should overloads with full signatures like deposit(uint256) be generated always, even if there are no overloads?
    externalArtifacts: ['externalArtifacts/*.json'], // optional array of glob patterns with external artifacts to process (for example external libs from node_modules)
    dontOverrideCompile: false // defaults to false
  },
  networks: {
    localhost: {
      url: "http://127.0.0.1:8545",
      accounts: customAccounts,
      blockGasLimit : 300_000_000,
      gas : 300_000_000
    },
    hardhat: {
      accounts: hardhatAccounts,
      blockGasLimit : 300_000_000,
      gas : 300_000_000
    },

    l1: {
      url: "http://127.0.0.1:9545",
      accounts: customAccounts
    },

    l2: {
      url: "http://127.0.0.1:8545",
      accounts: customAccounts
    },

    opGoerli: {
      //url: "https://goerli.optimism.io",
      url : "https://opt-goerli.g.alchemy.com/v2/FR5hJ_14k0N8hhJqnVNM803ymNsq5pOA",
      accounts: customAccounts
    },

    rinkeby: {
      gasPrice : `auto`,
      gas : 6000000,
      url: `https://eth-rinkeby.alchemyapi.io/v2/ZmcigLlVI7dckhbxFSTmg5LOuC1rjUbw`,
      accounts: customAccounts
    }
  },
  etherscan: {
    // https://hardhat.org/plugins/nomiclabs-hardhat-etherscan.html
    // npx hardhat verify --network mainnet DEPLOYED_CONTRACT_ADDRESS "Constructor argument 1"
    //apiKey: "PET6CJHW44RUBYAJ97MKMKTXS7JCWKS2B2"
    apiKey: "Y5UPE2DNZ3YN14XTDEC6D9H84XJMK7QX77"
  },
  mocha: {
    // retries : 2,
    //timeout : 600000
  },

  contractSizer: {
    runOnCompile: true
  },
};
