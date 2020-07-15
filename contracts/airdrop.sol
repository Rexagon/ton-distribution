pragma solidity >= 0.6.0;
pragma experimental ABIEncoderV2;
pragma AbiHeader expire;


/**
 * @title TONs distribution smart contract. Pretty close to the regular airdrops.
 */
contract Airdrop {
    address[] addresses;
    uint128[] amounts;
    address refund_destination;
    mapping(uint => bool) distributed;
    uint256 refund_lock_duration_end;

    uint total_amount = 0;

//    modifier alwaysAccept {
//        tvm.accept();
//
//        _;
//    }

    modifier refundLockPassed {
        require(now > refund_lock_duration_end);
        tvm.accept();

        _;
    }

    modifier balanceSufficient {
        require(address(this).balance > total_amount);
        tvm.accept();

        _;
    }


    /**
     * @dev Creates new contract. All contract parameters should be set up
     *      in constructor and can't be changed later.
     *
     * @param _refund_destination Receiver of the TONs in case of refund
     * @param _addresses List of receivers for distribution
     * @param _amounts   List of amounts specified for each receiver from the _addresses
     * @param _refund_lock_duration The duration of the refund lock in seconds. No more
     *      than 1 week = 604800 seconds. (fool tolerance)
     */
    constructor(
        address _refund_destination,
        address[] _addresses,
        uint128[] _amounts,
        uint256 _refund_lock_duration
    ) public {
        require(_amounts.length == _addresses.length);
        require(_amounts.length > 0);
        require(_refund_lock_duration <= 604800);
        tvm.accept();

        addresses = _addresses;
        amounts = _amounts;
        refund_destination = _refund_destination;

        refund_lock_duration_end = now + _refund_lock_duration;

        for (uint i=0; i < amounts.length; i++) {
            total_amount += amounts[i];
        }
    }

    /**
     * @dev Sends all contract's balance to the refund_destination
     *      Can be executed only after refund_lock_duration_end
     */
    function refund() refundLockPassed public view {
        payable(refund_destination).transfer(0, false, 128);
    }

    /**
     * @dev Distributes contract balance to the receivers from the addresses
     *      In case there was an error at some height, function can be re-called
     *      Without sending tokens to the already processed receivers.
     */
    function distribute() balanceSufficient public {
        for (uint i=0; i < addresses.length; i++) {
            if (distributed[i] == false) {
                distributed[i] = true;
                payable(addresses[i]).transfer(amounts[i], false, 3);
            }
        }
    }

    function get_addresses() external view returns(address[]) {
        return addresses;
    }

    function get_amounts() external view returns(uint128[]) {
        return amounts;
    }

    function get_refund_destination() external view returns(address) {
        return refund_destination;
    }

    function get_distributed_status(uint i) external view returns(bool) {
        return distributed[i];
    }

    function get_refund_lock_end_timestamp() external view returns(uint256) {
        return refund_lock_duration_end;
    }

    function get_current_balance() external pure returns(uint128) {
        return uint128(address(this).balance);
    }

    function get_total_amount() external view returns(uint) {
        return total_amount;
    }
}
