/**

 $$$$$$\                $$\                                               $$\
$$  __$$\               $$ |                                              $$ |
$$ /  $$ |$$\  $$\  $$\ $$ |  $$\ $$\  $$\  $$\  $$$$$$\   $$$$$$\   $$$$$$$ |
$$$$$$$$ |$$ | $$ | $$ |$$ | $$  |$$ | $$ | $$ | \____$$\ $$  __$$\ $$  __$$ |
$$  __$$ |$$ | $$ | $$ |$$$$$$  / $$ | $$ | $$ | $$$$$$$ |$$ |  \__|$$ /  $$ |
$$ |  $$ |$$ | $$ | $$ |$$  _$$<  $$ | $$ | $$ |$$  __$$ |$$ |      $$ |  $$ |
$$ |  $$ |\$$$$$\$$$$  |$$ | \$$\ \$$$$$\$$$$  |\$$$$$$$ |$$ |      \$$$$$$$ |
\__|  \__| \_____\____/ \__|  \__| \_____\____/  \_______|\__|       \_______|
                                                                              
                                                                              
$$\      $$\                     $$\                                          
$$$\    $$$ |                    $$ |                                         
$$$$\  $$$$ | $$$$$$\  $$$$$$$\  $$ |  $$\  $$$$$$\  $$\   $$\
$$\$$\$$ $$ |$$  __$$\ $$  __$$\ $$ | $$  |$$  __$$\ $$ |  $$ |
$$ \$$$  $$ |$$ /  $$ |$$ |  $$ |$$$$$$  / $$$$$$$$ |$$ |  $$ |
$$ |\$  /$$ |$$ |  $$ |$$ |  $$ |$$  _$$<  $$   ____|$$ |  $$ |
$$ | \_/ $$ |\$$$$$$  |$$ |  $$ |$$ | \$$\ \$$$$$$$\ \$$$$$$$ |
\__|     \__| \______/ \__|  \__|\__|  \__| \_______| \____$$ |
                                                     $$\   $$ |
                                                     \$$$$$$  |
                                                      \______/
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./Utils.sol";

contract AwkwardMonkey is Ownable, ERC20 {
    constructor() ERC20("Awkward Monkey", "AWKM") {
        _mint(_msgSender(), 420_690_420_690 * 10 ** 18);
        _transferOwnership(address(0));
    }
}
