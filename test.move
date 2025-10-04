address 0x1c6d89ac6b57c23e07ce431ea4e54ad340965d29aa4278c5767b211776361fc3 {
    module MicroInsuranceTest {
        use std::signer;
        use aptos_framework::aptos_coin::AptosCoin;
        use aptos_framework::coin;
        use 0x1c6d89ac6b57c23e07ce431ea4e54ad340965d29aa4278c5767b211776361fc3::MicroInsurance;

        #[test]
        fun test_initialize_and_create_pool(admin: &signer) {
            MicroInsurance::initialize(admin);

            let pool_name = vector::empty<u8>();
            MicroInsurance::create_pool(admin, pool_name, 1_000, 5_000);
        }

        #[test]
        fun test_pool_join_and_claim(user1: &signer, user2: &signer, admin: &signer) {
            MicroInsurance::initialize(admin);

            let pool_name = vector::empty<u8>();
            MicroInsurance::create_pool(admin, pool_name, 1_000, 5_000);
            let pool_id = 1;

            coin::mint<AptosCoin>(user1, 10_000);
            coin::mint<AptosCoin>(user2, 10_000);

            MicroInsurance::join_pool(user1, pool_id);
            MicroInsurance::join_pool(user2, pool_id);

            let claim_description = vector::empty<u8>();
            MicroInsurance::submit_claim(user1, pool_id, 3_000, claim_description);
        }

        #[test]
        fun test_voting_process(user1: &signer, user2: &signer, user3: &signer, admin: &signer) {
            MicroInsurance::initialize(admin);

            let pool_name = vector::empty<u8>();
            MicroInsurance::create_pool(admin, pool_name, 1_000, 5_000);
            let pool_id = 1;

            coin::mint<AptosCoin>(user1, 10_000);
            coin::mint<AptosCoin>(user2, 10_000);
            coin::mint<AptosCoin>(user3, 10_000);

            MicroInsurance::join_pool(user1, pool_id);
            MicroInsurance::join_pool(user2, pool_id);
            MicroInsurance::join_pool(user3, pool_id);

            let claim_desc = vector::empty<u8>();
            MicroInsurance::submit_claim(user1, pool_id, 3_000, claim_desc);
            let claim_id = 1;

            MicroInsurance::vote_on_claim(user1, claim_id, true);
            MicroInsurance::vote_on_claim(user2, claim_id, true);
            MicroInsurance::vote_on_claim(user3, claim_id, false);
        }
    }
}
