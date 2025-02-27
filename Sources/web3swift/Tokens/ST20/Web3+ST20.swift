//
//  Web3+ST20.swift
//
//  Created by Anton on 05/03/2019.
//  Copyright © 2019 The Matter Inc. All rights reserved.
//

import Foundation
import BigInt
import Web3Core

// NPolymath Token Standard
protocol IST20: IERC20 {
    // off-chain hash
    func tokenDetails() async throws -> [UInt32]

    // transfer, transferFrom must respect the result of verifyTransfer
    func verifyTransfer(from: EthereumAddress, originalOwner: EthereumAddress, to: EthereumAddress, amount: String) async throws -> WriteOperation

    // used to create tokens
    func mint(from: EthereumAddress, investor: EthereumAddress, amount: String) async throws -> WriteOperation

    // Burn function used to burn the securityToken
    func burn(from: EthereumAddress, amount: String) async throws -> WriteOperation
}

// This namespace contains functions to work with ST-20 tokens.
// can be imperatively read and saved
// FIXME: Rewrite this to CodableTransaction
public class ST20: IST20, ERC20BaseProperties {
    public private(set) var basePropertiesProvider: ERC20BasePropertiesProvider
    public var transaction: CodableTransaction
    public var web3: Web3
    public var provider: Web3Provider
    public var address: EthereumAddress
    public var abi: String

    public let contract: Web3.Contract

    public init(web3: Web3, provider: Web3Provider, address: EthereumAddress, abi: String = Web3.Utils.st20ABI, transaction: CodableTransaction = .emptyTransaction) {
        self.web3 = web3
        self.provider = provider
        self.address = address
        self.transaction = transaction
        self.transaction.to = address
        self.abi = abi
        // TODO: Make `init` and `web3.contract.init` throwing. Forced because this should fail if ABI is wrongly configured
        contract = web3.contract(abi, at: address)!
        basePropertiesProvider = ERC20BasePropertiesProvider(contract: contract)
    }

    func tokenDetails() async throws -> [UInt32] {
        let result = try await contract.createReadOperation("tokenDetails")!.call()

        guard let res = result["0"] as? [UInt32] else {throw Web3Error.processingError(desc: "Failed to get result of expected type from the Ethereum node")}
        return res
    }

    func verifyTransfer(from: EthereumAddress, originalOwner: EthereumAddress, to: EthereumAddress, amount: String) async throws -> WriteOperation {
        transaction.callOnBlock = .latest
        updateTransactionAndContract(from: from)
        // get the decimals manually
        let callResult = try await contract.createReadOperation("decimals")!.call()
        var decimals = BigUInt(0)
        guard let dec = callResult["0"], let decTyped = dec as? BigUInt else {
            throw Web3Error.inputError(desc: "Contract may be not ERC20 compatible, can not get decimals")}
        decimals = decTyped

        let intDecimals = Int(decimals)
        guard let value = Utilities.parseToBigUInt(amount, decimals: intDecimals) else {
            throw Web3Error.inputError(desc: "Can not parse inputted amount")
        }

        let tx = contract.createWriteOperation("verifyTransfer", parameters: [originalOwner, to, value])!
        return tx
    }

    func mint(from: EthereumAddress, investor: EthereumAddress, amount: String) async throws -> WriteOperation {
        transaction.callOnBlock = .latest
        updateTransactionAndContract(from: from)
        // get the decimals manually
        let callResult = try await contract.createReadOperation("decimals")!.call()
        var decimals = BigUInt(0)
        guard let dec = callResult["0"], let decTyped = dec as? BigUInt else {
            throw Web3Error.inputError(desc: "Contract may be not ERC20 compatible, can not get decimals")}
        decimals = decTyped

        let intDecimals = Int(decimals)
        guard let value = Utilities.parseToBigUInt(amount, decimals: intDecimals) else {
            throw Web3Error.inputError(desc: "Can not parse inputted amount")
        }

        let tx = contract.createWriteOperation("mint", parameters: [investor, value])!
        return tx
    }

    public func burn(from: EthereumAddress, amount: String) async throws -> WriteOperation {
        transaction.callOnBlock = .latest
        updateTransactionAndContract(from: from)
        // get the decimals manually
        let callResult = try await contract.createReadOperation("decimals")!.call()
        var decimals = BigUInt(0)
        guard let dec = callResult["0"], let decTyped = dec as? BigUInt else {
            throw Web3Error.inputError(desc: "Contract may be not ERC20 compatible, can not get decimals")}
        decimals = decTyped

        let intDecimals = Int(decimals)
        guard let value = Utilities.parseToBigUInt(amount, decimals: intDecimals) else {
            throw Web3Error.inputError(desc: "Can not parse inputted amount")
        }

        let tx = contract.createWriteOperation("burn", parameters: [value])!
        return tx
    }

    public func getBalance(account: EthereumAddress) async throws -> BigUInt {
        let result = try await contract.createReadOperation("balanceOf", parameters: [account])!.call()

        guard let res = result["0"] as? BigUInt else {throw Web3Error.processingError(desc: "Failed to get result of expected type from the Ethereum node")}
        return res
    }

    public func getAllowance(originalOwner: EthereumAddress, delegate: EthereumAddress) async throws -> BigUInt {
        let result = try await contract.createReadOperation("allowance", parameters: [originalOwner, delegate])!.call()

        guard let res = result["0"] as? BigUInt else {throw Web3Error.processingError(desc: "Failed to get result of expected type from the Ethereum node")}
        return res
    }

    public func transfer(from: EthereumAddress, to: EthereumAddress, amount: String) async throws -> WriteOperation {
        transaction.callOnBlock = .latest
        updateTransactionAndContract(from: from)
        // get the decimals manually
        let callResult = try await contract.createReadOperation("decimals")!.call()
        var decimals = BigUInt(0)
        guard let dec = callResult["0"], let decTyped = dec as? BigUInt else {
            throw Web3Error.inputError(desc: "Contract may be not ERC20 compatible, can not get decimals")}
        decimals = decTyped

        let intDecimals = Int(decimals)
        guard let value = Utilities.parseToBigUInt(amount, decimals: intDecimals) else {
            throw Web3Error.inputError(desc: "Can not parse inputted amount")
        }

        let tx = contract.createWriteOperation("transfer", parameters: [to, value])!
        return tx
    }

    public func transferFrom(from: EthereumAddress, to: EthereumAddress, originalOwner: EthereumAddress, amount: String) async throws -> WriteOperation {
        transaction.callOnBlock = .latest
        updateTransactionAndContract(from: from)
        // get the decimals manually
        let callResult = try await contract.createReadOperation("decimals")!.call()
        var decimals = BigUInt(0)
        guard let dec = callResult["0"], let decTyped = dec as? BigUInt else {
            throw Web3Error.inputError(desc: "Contract may be not ERC20 compatible, can not get decimals")}
        decimals = decTyped

        let intDecimals = Int(decimals)
        guard let value = Utilities.parseToBigUInt(amount, decimals: intDecimals) else {
            throw Web3Error.inputError(desc: "Can not parse inputted amount")
        }

        let tx = contract.createWriteOperation("transferFrom", parameters: [originalOwner, to, value])!
        return tx
    }

    public func setAllowance(from: EthereumAddress, to: EthereumAddress, newAmount: String) async throws -> WriteOperation {
        transaction.callOnBlock = .latest
        updateTransactionAndContract(from: from)
        // get the decimals manually
        let callResult = try await contract.createReadOperation("decimals")!.call()
        var decimals = BigUInt(0)
        guard let dec = callResult["0"], let decTyped = dec as? BigUInt else {
            throw Web3Error.inputError(desc: "Contract may be not ERC20 compatible, can not get decimals")}
        decimals = decTyped

        let intDecimals = Int(decimals)
        guard let value = Utilities.parseToBigUInt(newAmount, decimals: intDecimals) else {
            throw Web3Error.inputError(desc: "Can not parse inputted amount")
        }

        let tx = contract.createWriteOperation("setAllowance", parameters: [to, value])!
        return tx
    }

    public func approve(from: EthereumAddress, spender: EthereumAddress, amount: String) async throws -> WriteOperation {
        transaction.callOnBlock = .latest
        updateTransactionAndContract(from: from)
        // get the decimals manually
        let callResult = try await contract.createReadOperation("decimals")!.call()
        var decimals = BigUInt(0)
        guard let dec = callResult["0"], let decTyped = dec as? BigUInt else {
            throw Web3Error.inputError(desc: "Contract may be not ERC20 compatible, can not get decimals")}
        decimals = decTyped

        let intDecimals = Int(decimals)
        guard let value = Utilities.parseToBigUInt(amount, decimals: intDecimals) else {
            throw Web3Error.inputError(desc: "Can not parse inputted amount")
        }

        let tx = contract.createWriteOperation("approve", parameters: [spender, value])!
        return tx
    }

    public func totalSupply() async throws -> BigUInt {
        let result = try await contract.createReadOperation("totalSupply")!.call()

        guard let res = result["0"] as? BigUInt else {throw Web3Error.processingError(desc: "Failed to get result of expected type from the Ethereum node")}
        return res
    }

}

// MARK: - Private

extension ST20 {

    private func updateTransactionAndContract(from: EthereumAddress) {
        transaction.from = from
        transaction.to = address
        contract.transaction = transaction
    }

}
