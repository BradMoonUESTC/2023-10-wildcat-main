// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.17;

import 'src/interfaces/IERC20Metadata.sol';
import { DSTestPlus } from 'solmate/test/utils/DSTestPlus.sol';
import { DSInvariantTest } from 'solmate/test/utils/DSInvariantTest.sol';

bytes32 constant PERMIT_TYPEHASH = keccak256(
  'Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)'
);

/**
 * @dev Abstract ERC20 test contract.
 * Set token, name, symbol, decimals in setUp function and provide
 * an implementation for `_mint`
 * @author transmissions11
 * Modified from https://github.com/transmissions11/solmate
 */
abstract contract BaseERC20Test is DSTestPlus {
  IERC20Metadata token;
  string _name;
  string _symbol;
  uint8 _decimals;

  function _mint(address to, uint256 amount) internal virtual;

  function setUp() public virtual;

  function invariantMetadata() public {
    assertEq(token.name(), _name);
    assertEq(token.symbol(), _symbol);
    assertEq(token.decimals(), _decimals);
  }

  function testMint() public {
    _mint(address(0xBEEF), 1e18);

    assertEq(token.totalSupply(), 1e18);
    assertEq(token.balanceOf(address(0xBEEF)), 1e18);
  }

  function testApprove() public {
    assertTrue(token.approve(address(0xBEEF), 1e18));

    assertEq(token.allowance(address(this), address(0xBEEF)), 1e18);
  }

  function testTransfer() public {
    _mint(address(this), 1e18);

    assertTrue(token.transfer(address(0xBEEF), 1e18));
    assertEq(token.totalSupply(), 1e18);

    assertEq(token.balanceOf(address(this)), 0);
    assertEq(token.balanceOf(address(0xBEEF)), 1e18);
  }

  function testTransferFrom() public {
    address from = address(0xABCD);

    _mint(from, 1e18);

    hevm.prank(from);
    token.approve(address(this), 1e18);

    assertTrue(token.transferFrom(from, address(0xBEEF), 1e18));
    assertEq(token.totalSupply(), 1e18);

    assertEq(token.allowance(from, address(this)), 0);

    assertEq(token.balanceOf(from), 0);
    assertEq(token.balanceOf(address(0xBEEF)), 1e18);
  }

  function testInfiniteApproveTransferFrom() public {
    address from = address(0xABCD);

    _mint(from, 1e18);

    hevm.prank(from);
    token.approve(address(this), type(uint256).max);

    assertTrue(token.transferFrom(from, address(0xBEEF), 1e18));
    assertEq(token.totalSupply(), 1e18);

    assertEq(token.allowance(from, address(this)), type(uint256).max);

    assertEq(token.balanceOf(from), 0);
    assertEq(token.balanceOf(address(0xBEEF)), 1e18);
  }

  // function testPermit() public {
  //     uint256 privateKey = 0xBEEF;
  //     address owner = hevm.addr(privateKey);

  //     (uint8 v, bytes32 r, bytes32 s) = hevm.sign(
  //         privateKey,
  //         keccak256(
  //             abi.encodePacked(
  //                 "\x19\x01",
  //                 token.DOMAIN_SEPARATOR(),
  //                 keccak256(abi.encode(PERMIT_TYPEHASH, owner, address(0xCAFE), 1e18, 0, block.timestamp))
  //             )
  //         )
  //     );

  //     token.permit(owner, address(0xCAFE), 1e18, block.timestamp, v, r, s);

  //     assertEq(token.allowance(owner, address(0xCAFE)), 1e18);
  //     assertEq(token.nonces(owner), 1);
  // }

  function testFailTransferInsufficientBalance() public {
    _mint(address(this), 0.9e18);
    token.transfer(address(0xBEEF), 1e18);
  }

  function testFailTransferFromInsufficientAllowance() public {
    address from = address(0xABCD);

    _mint(from, 1e18);

    hevm.prank(from);
    token.approve(address(this), 0.9e18);

    token.transferFrom(from, address(0xBEEF), 1e18);
  }

  function testFailTransferFromInsufficientBalance() public {
    address from = address(0xABCD);

    _mint(from, 0.9e18);

    hevm.prank(from);
    token.approve(address(this), 1e18);

    token.transferFrom(from, address(0xBEEF), 1e18);
  }

  // function testFailPermitBadNonce() public {
  // 	uint256 privateKey = 0xBEEF;
  // 	address owner = hevm.addr(privateKey);

  // 	(uint8 v, bytes32 r, bytes32 s) = hevm.sign(
  // 		privateKey,
  // 		keccak256(
  // 			abi.encodePacked(
  // 				'\x19\x01',
  // 				token.DOMAIN_SEPARATOR(),
  // 				keccak256(
  // 					abi.encode(
  // 						PERMIT_TYPEHASH,
  // 						owner,
  // 						address(0xCAFE),
  // 						1e18,
  // 						1,
  // 						block.timestamp
  // 					)
  // 				)
  // 			)
  // 		)
  // 	);

  // 	token.permit(owner, address(0xCAFE), 1e18, block.timestamp, v, r, s);
  // }

  // function testFailPermitBadDeadline() public {
  // 	uint256 privateKey = 0xBEEF;
  // 	address owner = hevm.addr(privateKey);

  // 	(uint8 v, bytes32 r, bytes32 s) = hevm.sign(
  // 		privateKey,
  // 		keccak256(
  // 			abi.encodePacked(
  // 				'\x19\x01',
  // 				token.DOMAIN_SEPARATOR(),
  // 				keccak256(
  // 					abi.encode(
  // 						PERMIT_TYPEHASH,
  // 						owner,
  // 						address(0xCAFE),
  // 						1e18,
  // 						0,
  // 						block.timestamp
  // 					)
  // 				)
  // 			)
  // 		)
  // 	);

  // 	token.permit(owner, address(0xCAFE), 1e18, block.timestamp + 1, v, r, s);
  // }

  // function testFailPermitPastDeadline() public {
  // 	uint256 oldTimestamp = block.timestamp;
  // 	uint256 privateKey = 0xBEEF;
  // 	address owner = hevm.addr(privateKey);

  // 	(uint8 v, bytes32 r, bytes32 s) = hevm.sign(
  // 		privateKey,
  // 		keccak256(
  // 			abi.encodePacked(
  // 				'\x19\x01',
  // 				token.DOMAIN_SEPARATOR(),
  // 				keccak256(
  // 					abi.encode(
  // 						PERMIT_TYPEHASH,
  // 						owner,
  // 						address(0xCAFE),
  // 						1e18,
  // 						0,
  // 						oldTimestamp
  // 					)
  // 				)
  // 			)
  // 		)
  // 	);

  // 	hevm.warp(block.timestamp + 1);
  // 	token.permit(owner, address(0xCAFE), 1e18, oldTimestamp, v, r, s);
  // }

  // function testFailPermitReplay() public {
  // 	uint256 privateKey = 0xBEEF;
  // 	address owner = hevm.addr(privateKey);

  // 	(uint8 v, bytes32 r, bytes32 s) = hevm.sign(
  // 		privateKey,
  // 		keccak256(
  // 			abi.encodePacked(
  // 				'\x19\x01',
  // 				token.DOMAIN_SEPARATOR(),
  // 				keccak256(
  // 					abi.encode(
  // 						PERMIT_TYPEHASH,
  // 						owner,
  // 						address(0xCAFE),
  // 						1e18,
  // 						0,
  // 						block.timestamp
  // 					)
  // 				)
  // 			)
  // 		)
  // 	);

  // 	token.permit(owner, address(0xCAFE), 1e18, block.timestamp, v, r, s);
  // 	token.permit(owner, address(0xCAFE), 1e18, block.timestamp, v, r, s);
  // }

  function testMint(address from, uint256 amount) public {
    _mint(from, amount);

    assertEq(token.totalSupply(), amount);
    assertEq(token.balanceOf(from), amount);
  }

  // function testBurn(
  //     address from,
  //     uint256 mintAmount,
  //     uint256 burnAmount
  // ) public {
  //     burnAmount = bound(burnAmount, 0, mintAmount);

  //     _mint(from, mintAmount);
  //     token.burn(from, burnAmount);

  //     assertEq(token.totalSupply(), mintAmount - burnAmount);
  //     assertEq(token.balanceOf(from), mintAmount - burnAmount);
  // }

  function testApprove(address to, uint256 amount) public {
    assertTrue(token.approve(to, amount));

    assertEq(token.allowance(address(this), to), amount);
  }

  function testTransfer(address from, uint256 amount) public {
    _mint(address(this), amount);

    assertTrue(token.transfer(from, amount));
    assertEq(token.totalSupply(), amount);

    if (address(this) == from) {
      assertEq(token.balanceOf(address(this)), amount);
    } else {
      assertEq(token.balanceOf(address(this)), 0);
      assertEq(token.balanceOf(from), amount);
    }
  }

  function testTransferFrom(address to, uint256 approval, uint256 amount) public {
    amount = bound(amount, 0, approval);

    address from = address(0xABCD);

    _mint(from, amount);

    hevm.prank(from);
    token.approve(address(this), approval);

    assertTrue(token.transferFrom(from, to, amount));
    assertEq(token.totalSupply(), amount);

    uint256 app = from == address(this) || approval == type(uint256).max
      ? approval
      : approval - amount;
    assertEq(token.allowance(from, address(this)), app);

    if (from == to) {
      assertEq(token.balanceOf(from), amount);
    } else {
      assertEq(token.balanceOf(from), 0);
      assertEq(token.balanceOf(to), amount);
    }
  }

  // function testPermit(
  //     uint248 privKey,
  //     address to,
  //     uint256 amount,
  //     uint256 deadline
  // ) public {
  //     uint256 privateKey = privKey;
  //     if (deadline < block.timestamp) deadline = block.timestamp;
  //     if (privateKey == 0) privateKey = 1;

  //     address owner = hevm.addr(privateKey);

  //     (uint8 v, bytes32 r, bytes32 s) = hevm.sign(
  //         privateKey,
  //         keccak256(
  //             abi.encodePacked(
  //                 "\x19\x01",
  //                 token.DOMAIN_SEPARATOR(),
  //                 keccak256(abi.encode(PERMIT_TYPEHASH, owner, to, amount, 0, deadline))
  //             )
  //         )
  //     );

  //     token.permit(owner, to, amount, deadline, v, r, s);

  //     assertEq(token.allowance(owner, to), amount);
  //     assertEq(token.nonces(owner), 1);
  // }

  // function testFailBurnInsufficientBalance(
  //     address to,
  //     uint256 mintAmount,
  //     uint256 burnAmount
  // ) public {
  //     burnAmount = bound(burnAmount, mintAmount + 1, type(uint256).max);

  //     _mint(to, mintAmount);
  //     token.burn(to, burnAmount);
  // }

  function testFailTransferInsufficientBalance(
    address to,
    uint256 mintAmount,
    uint256 sendAmount
  ) public {
    sendAmount = bound(sendAmount, mintAmount + 1, type(uint256).max);

    _mint(address(this), mintAmount);
    token.transfer(to, sendAmount);
  }

  function testFailTransferFromInsufficientAllowance(
    address to,
    uint256 approval,
    uint256 amount
  ) public {
    amount = bound(amount, approval + 1, type(uint256).max);

    address from = address(0xABCD);

    _mint(from, amount);

    hevm.prank(from);
    token.approve(address(this), approval);

    token.transferFrom(from, to, amount);
  }

  function testFailTransferFromInsufficientBalance(
    address to,
    uint256 mintAmount,
    uint256 sendAmount
  ) public {
    sendAmount = bound(sendAmount, mintAmount + 1, type(uint256).max);

    address from = address(0xABCD);

    _mint(from, mintAmount);

    hevm.prank(from);
    token.approve(address(this), sendAmount);

    token.transferFrom(from, to, sendAmount);
  }

  // function testFailPermitBadNonce(
  //     uint256 privateKey,
  //     address to,
  //     uint256 amount,
  //     uint256 deadline,
  //     uint256 nonce
  // ) public {
  //     if (deadline < block.timestamp) deadline = block.timestamp;
  //     if (privateKey == 0) privateKey = 1;
  //     if (nonce == 0) nonce = 1;

  //     address owner = hevm.addr(privateKey);

  //     (uint8 v, bytes32 r, bytes32 s) = hevm.sign(
  //         privateKey,
  //         keccak256(
  //             abi.encodePacked(
  //                 "\x19\x01",
  //                 token.DOMAIN_SEPARATOR(),
  //                 keccak256(abi.encode(PERMIT_TYPEHASH, owner, to, amount, nonce, deadline))
  //             )
  //         )
  //     );

  //     token.permit(owner, to, amount, deadline, v, r, s);
  // }

  // function testFailPermitBadDeadline(
  //     uint256 privateKey,
  //     address to,
  //     uint256 amount,
  //     uint256 deadline
  // ) public {
  //     if (deadline < block.timestamp) deadline = block.timestamp;
  //     if (privateKey == 0) privateKey = 1;

  //     address owner = hevm.addr(privateKey);

  //     (uint8 v, bytes32 r, bytes32 s) = hevm.sign(
  //         privateKey,
  //         keccak256(
  //             abi.encodePacked(
  //                 "\x19\x01",
  //                 token.DOMAIN_SEPARATOR(),
  //                 keccak256(abi.encode(PERMIT_TYPEHASH, owner, to, amount, 0, deadline))
  //             )
  //         )
  //     );

  //     token.permit(owner, to, amount, deadline + 1, v, r, s);
  // }

  // function testFailPermitPastDeadline(
  //     uint256 privateKey,
  //     address to,
  //     uint256 amount,
  //     uint256 deadline
  // ) public {
  //     deadline = bound(deadline, 0, block.timestamp - 1);
  //     if (privateKey == 0) privateKey = 1;

  //     address owner = hevm.addr(privateKey);

  //     (uint8 v, bytes32 r, bytes32 s) = hevm.sign(
  //         privateKey,
  //         keccak256(
  //             abi.encodePacked(
  //                 "\x19\x01",
  //                 token.DOMAIN_SEPARATOR(),
  //                 keccak256(abi.encode(PERMIT_TYPEHASH, owner, to, amount, 0, deadline))
  //             )
  //         )
  //     );

  //     token.permit(owner, to, amount, deadline, v, r, s);
  // }

  // function testFailPermitReplay(
  //     uint256 privateKey,
  //     address to,
  //     uint256 amount,
  //     uint256 deadline
  // ) public {
  //     if (deadline < block.timestamp) deadline = block.timestamp;
  //     if (privateKey == 0) privateKey = 1;

  //     address owner = hevm.addr(privateKey);

  //     (uint8 v, bytes32 r, bytes32 s) = hevm.sign(
  //         privateKey,
  //         keccak256(
  //             abi.encodePacked(
  //                 "\x19\x01",
  //                 token.DOMAIN_SEPARATOR(),
  //                 keccak256(abi.encode(PERMIT_TYPEHASH, owner, to, amount, 0, deadline))
  //             )
  //         )
  //     );

  //     token.permit(owner, to, amount, deadline, v, r, s);
  //     token.permit(owner, to, amount, deadline, v, r, s);
  // }
}

// contract ERC20Invariants is DSTestPlus, DSInvariantTest {
// 	BalanceSum balanceSum;
// 	IERC20Metadata token;

// 	function setUp() public {
// 		token = new MockERC20('Token', 'TKN', 18);
// 		balanceSum = new BalanceSum(token);

// 		addTargetContract(address(balanceSum));
// 	}

// 	function invariantBalanceSum() public {
// 		assertEq(token.totalSupply(), balanceSum.sum());
// 	}
// }

// contract BalanceSum {
// 	IERC20Metadata token;
// 	uint256 public sum;

// 	constructor(IERC20Metadata _token) {
// 		token = _token;
// 	}

// 	function mint(address from, uint256 amount) public {
// 		_mint(from, amount);
// 		sum += amount;
// 	}

// 	function burn(address from, uint256 amount) public {
// 		token.burn(from, amount);
// 		sum -= amount;
// 	}

// 	function approve(address to, uint256 amount) public {
// 		token.approve(to, amount);
// 	}

// 	function transferFrom(address from, address to, uint256 amount) public {
// 		token.transferFrom(from, to, amount);
// 	}

// 	function transfer(address to, uint256 amount) public {
// 		token.transfer(to, amount);
// 	}
// }
