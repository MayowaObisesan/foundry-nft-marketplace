// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

library SignUtils {
    function constructMessageHash(
        address _token,
        uint256 _tokenId,
        uint256 _price,
        uint88 _deadline,
        address _seller
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(_token, _tokenId, _price, _deadline, _seller)
            );
    }

    function isValid(
        bytes32 messageHash,
        bytes memory signature,
        address signer
    ) internal pure returns (bool) {
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, signature) == signer;
        // return
        //     recoverSigner(ethSignedMessageHash, signature) ==
        //     address(uint160(signer));
    }

    function getEthSignedMessageHash(
        bytes32 messageHash
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    messageHash
                )
            );
    }

    function recoverSigner(
        bytes32 ethSignedMessageHash,
        bytes memory signature
    ) internal pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(signature);

        return ecrecover(ethSignedMessageHash, v, r, s);
    }

    function splitSignature(
        bytes memory sig
    ) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "Invalid signature length");

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        } // implicitly return (r, s, v)
    }
}
