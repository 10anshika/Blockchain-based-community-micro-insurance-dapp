address 0x1c6d89ac6b57c23e07ce431ea4e54ad340965d29aa4278c5767b211776361fc3 {
    module MicroInsuranceTest {
        use std::signer;
        use std::vector;
        use std::string;
        use aptos_framework::aptos_coin::{Self, AptosCoin};
        use aptos_framework::coin;
        use aptos_framework::account;
        use MicroInsurance

        // Test helper function to initialize Aptos coin for testing
        #[test_only]
        fun init_aptos_coin_for_test() {
            let aptos_framework = account::create_signer_for_test(@0x1);
            let (burn_cap, mint_cap) = aptos_coin::initialize_for_test(&aptos_framework);
            coin::destroy_burn_cap(burn_cap);
            coin::destroy_mint_cap(mint_cap);
        }

        // Test helper to setup account with APT
        #[test_only]
        fun setup_account_with_apt(account: &signer, amount: u64) {
            let addr = signer::address_of(account);
            account::create_account_for_test(addr);
            
            // Register for APT if not already registered
            if (!coin::is_account_registered<AptosCoin>(addr)) {
                coin::register<AptosCoin>(account);
            };
            
            // Create mint capability for testing
            let aptos_framework = account::create_signer_for_test(@0x1);
            aptos_coin::mint(&aptos_framework, addr, amount);
        }

        #[test(admin = @0x123)]
        fun test_initialize_and_create_pool(admin: signer) {
            // Initialize Aptos coin for testing
            init_aptos_coin_for_test();
            
            // Setup admin account
            setup_account_with_apt(&admin, 100_000);

            // Initialize the MicroInsurance module
            MicroInsurance::initialize(&admin);

            // Create a pool with meaningful parameters
            let pool_name = b"Test Insurance Pool";
            let contribution_amount = 1_000; // 0.00001 APT
            let max_claim_amount = 5_000;    // 0.00005 APT
            
            MicroInsurance::create_pool(&admin, pool_name, contribution_amount, max_claim_amount);
            
            // Verify pool was created (you would need a getter function in your main module)
            // This assumes you have a view function to check pool existence
            // assert!(MicroInsurance::pool_exists(1), 1);
        }

        #[test(user1 = @0x456, user2 = @0x789, admin = @0x123)]
        fun test_pool_join_and_claim(user1: signer, user2: signer, admin: signer) {
            // Initialize Aptos coin for testing
            init_aptos_coin_for_test();
            
            // Setup all accounts with sufficient APT
            setup_account_with_apt(&admin, 100_000);
            setup_account_with_apt(&user1, 10_000);
            setup_account_with_apt(&user2, 10_000);

            // Initialize the MicroInsurance module
            MicroInsurance::initialize(&admin);

            // Create a pool
            let pool_name = b"Test Pool";
            let contribution_amount = 1_000;
            let max_claim_amount = 5_000;
            MicroInsurance::create_pool(&admin, pool_name, contribution_amount, max_claim_amount);
            let pool_id = 1;

            // Users join the pool
            MicroInsurance::join_pool(&user1, pool_id);
            MicroInsurance::join_pool(&user2, pool_id);

            // User1 submits a claim
            let claim_description = b"Medical emergency claim";
            let claim_amount = 3_000;
            MicroInsurance::submit_claim(&user1, pool_id, claim_amount, claim_description);
            
            // Verify claim was submitted
            // assert!(MicroInsurance::claim_exists(1), 1);
        }

        #[test(user1 = @0x456, user2 = @0x789, user3 = @0x101, admin = @0x123)]
        fun test_voting_process(user1: signer, user2: signer, user3: signer, admin: signer) {
            // Initialize Aptos coin for testing
            init_aptos_coin_for_test();
            
            // Setup all accounts with sufficient APT
            setup_account_with_apt(&admin, 100_000);
            setup_account_with_apt(&user1, 10_000);
            setup_account_with_apt(&user2, 10_000);
            setup_account_with_apt(&user3, 10_000);

            // Initialize the MicroInsurance module
            MicroInsurance::initialize(&admin);

            // Create a pool
            let pool_name = b"Voting Test Pool";
            let contribution_amount = 1_000;
            let max_claim_amount = 5_000;
            MicroInsurance::create_pool(&admin, pool_name, contribution_amount, max_claim_amount);
            let pool_id = 1;

            // All users join the pool
            MicroInsurance::join_pool(&user1, pool_id);
            MicroInsurance::join_pool(&user2, pool_id);
            MicroInsurance::join_pool(&user3, pool_id);

            // User1 submits a claim
            let claim_description = b"Test claim for voting";
            let claim_amount = 3_000;
            MicroInsurance::submit_claim(&user1, pool_id, claim_amount, claim_description);
            let claim_id = 1;

            // Users vote on the claim
            MicroInsurance::vote_on_claim(&user1, claim_id, true);   // Approve
            MicroInsurance::vote_on_claim(&user2, claim_id, true);   // Approve
            MicroInsurance::vote_on_claim(&user3, claim_id, false);  // Reject

            // Verify voting process completed
            // You would need getter functions to verify the voting results
            // let vote_count = MicroInsurance::get_approval_votes(claim_id);
            // assert!(vote_count == 2, 1);
        }

        #[test(admin = @0x123)]
        #[expected_failure(abort_code = 1, location = Self)] // Assuming error code 1 for unauthorized
        fun test_unauthorized_pool_creation(admin: signer) {
            // Initialize Aptos coin for testing
            init_aptos_coin_for_test();
            setup_account_with_apt(&admin, 100_000);

            // Try to create pool without initializing - should fail
            let pool_name = b"Unauthorized Pool";
            MicroInsurance::create_pool(&admin, pool_name, 1_000, 5_000);
        }

        #[test(user1 = @0x456, admin = @0x123)]
        #[expected_failure] // This should fail because user doesn't have enough contribution
        fun test_insufficient_funds_join_pool(user1: signer, admin: signer) {
            // Initialize Aptos coin for testing
            init_aptos_coin_for_test();
            
            // Setup admin with funds, user with insufficient funds
            setup_account_with_apt(&admin, 100_000);
            setup_account_with_apt(&user1, 500); // Less than required contribution

            // Initialize and create pool
            MicroInsurance::initialize(&admin);
            MicroInsurance::create_pool(&admin, b"Test Pool", 1_000, 5_000);

            // This should fail due to insufficient funds
            MicroInsurance::join_pool(&user1, 1);
        }

        #[test(user1 = @0x456, user2 = @0x789, admin = @0x123)]
        fun test_edge_case_empty_pool_name(user1: signer, user2: signer, admin: signer) {
            // Initialize Aptos coin for testing
            init_aptos_coin_for_test();
            
            // Setup accounts
            setup_account_with_apt(&admin, 100_000);
            setup_account_with_apt(&user1, 10_000);
            setup_account_with_apt(&user2, 10_000);

            // Initialize the MicroInsurance module
            MicroInsurance::initialize(&admin);

            // Create pool with empty name - should still work
            let empty_pool_name = b"";
            MicroInsurance::create_pool(&admin, empty_pool_name, 1_000, 5_000);

            // Test that users can still join
            MicroInsurance::join_pool(&user1, 1);
            MicroInsurance::join_pool(&user2, 1);
        }

        #[test(user1 = @0x456, admin = @0x123)]
        fun test_claim_with_empty_description(user1: signer, admin: signer) {
            // Initialize Aptos coin for testing
            init_aptos_coin_for_test();
            
            // Setup accounts
            setup_account_with_apt(&admin, 100_000);
            setup_account_with_apt(&user1, 10_000);

            // Initialize and setup pool
            MicroInsurance::initialize(&admin);
            MicroInsurance::create_pool(&admin, b"Test Pool", 1_000, 5_000);
            MicroInsurance::join_pool(&user1, 1);

            // Submit claim with empty description
            let empty_description = b"";
            MicroInsurance::submit_claim(&user1, 1, 2_000, empty_description);
        }
    }
}
