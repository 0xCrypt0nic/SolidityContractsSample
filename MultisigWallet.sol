// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

contract MultisigWallet {
    struct Transaction {
        address to;
        uint value;
        uint votes;
        uint deadline;
        bool executed;
    }

    event TransactionProposed(address proposer, address to, uint value);

    uint public quorum;
    Transaction[] public transactions;

    mapping(address account => bool isSigner) public signers;
    mapping(uint id => mapping(address signer => bool validated))
        public validations;

    modifier onlySigner() {
        require(signers[msg.sender] == true, "Not signer");
        _;
    }

    constructor(uint quorum_, address[] memory signers_) {
        require(quorum_ > 1 && quorum_ <= signers_.length);
        quorum = quorum_;

        for (uint i = 0; i < signers_.length; i++) {
            address signer = signers_[i];
            require(signer != address(0), "Address zero");
            require(signers[signer] == false, "Duplicate signer");
            signers[signer] = true;
        }
    }

    function transactionCount() external view returns (uint) {
        return transactions.length;
    }

    function proposeTransaction(address to, uint value) external onlySigner {
        uint id = transactions.length;
        transactions.push(
            Transaction({
                to: to,
                value: value,
                votes: 1,
                deadline: block.timestamp + 1 days,
                executed: false
            })
        );
        validations[id][msg.sender] = true;

        emit TransactionProposed(msg.sender, to, value);
    }

    function validateTransaction(uint id) external onlySigner {
        require(validations[id][msg.sender] == false, "Already validated");
        require(transactions[id].executed == false, "Already executed");
        require(
            block.timestamp < transactions[id].deadline,
            "Invalid transaction"
        );

        transactions[id].votes++;
        validations[id][msg.sender] = true;

        if (transactions[id].votes >= quorum) {
            address payable to = payable(transactions[id].to);
            uint value = transactions[id].value;
            to.transfer(value);
            transactions[id].executed = true;
        }
    }

    receive() external payable {}
}
