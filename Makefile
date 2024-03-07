-include .env


deploy-sepolia:
	forge script script/DeployRise_In_Decentralized_Market.s.sol:DeployDecentralized_Market --rpc-url $(SEPOILA_RPC_URL) --private-key $(SEPOILA_PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv

deploy-anvil:
	forge script script/DeployRise_In_Decentralized_Market.s.sol:DeployDecentralized_Market --rpc-url $(ANVIL_RPC_URL) --private-key $(ANVIL_PRIVATE_KEY) --broadcast

compile:
	forge compile

chainlink-brownie-contracts:
	forge install smartcontractkit/chainlink-brownie-contracts@0.6.1 https://github.com/smartcontractkit/chainlink-brownie-contracts --no-git


