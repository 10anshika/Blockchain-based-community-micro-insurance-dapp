# app.py
import os
import asyncio
import streamlit as st

from aptos_sdk.account import Account
from aptos_sdk.async_client import RestClient
from aptos_sdk.transactions import EntryFunction, TransactionPayload, TransactionArgument
from aptos_sdk.bcs import Serializer

# =====================
# CONFIG
# =====================
NODE_URL = "https://fullnode.testnet.aptoslabs.com/v1"
MODULE_ADDRESS = "0x1c6d89ac6b57c23e07ce431ea4e54ad340965d29aa4278c5767b211776361fc3"
CLIENT = RestClient(NODE_URL)

# =====================
# PAGE
# =====================
st.set_page_config(
    page_title="SecurePool | MicroInsurance DApp",
    page_icon="🛡",
    layout="wide",
    initial_sidebar_state="collapsed",
)

# =====================
# HELPERS
# =====================

def create_account():
    """Create a new Aptos account and store it in session state."""
    try:
        private_key_hex = os.urandom(32).hex()
        account = Account.load_key(private_key_hex)
        st.session_state["account"] = account
        st.success(f"✅ Demo account created.\n\nAddress: {account.address()}")
        return account
    except Exception as e:
        st.error(f"❌ Failed to create account: {e}")
        return None


def get_account():
    return st.session_state.get("account", None)


async def _submit_entry_function(account: Account, module_addr: str, module_name: str,
                                 func_name: str, args: list):
    """
    Build -> sign -> submit -> wait for an entry function transaction.
    Works with aptos_sdk Python package.
    """
    try:
        entry_func = EntryFunction.natural(
            f"{module_addr}::{module_name}",
            func_name,
            [],
            args,
        )
        payload = TransactionPayload(entry_func)

        # ✅ FIXED: directly build signed txn
        signed_txn = CLIENT.create_bcs_transaction(account, payload)

        # ✅ Submit
        tx_hash = CLIENT.submit_bcs_transaction(signed_txn)

        # ✅ Wait
        CLIENT.wait_for_transaction(tx_hash)

        return tx_hash
    except Exception as e:
        raise RuntimeError(f"Transaction failed: {e}")


        return tx_hash
    except Exception as e:
        raise RuntimeError(f"Transaction failed: {e}")


# ----- App actions (async) -----

async def publish_pool_async(name: str, premium: int, coverage: int):
    account = get_account()
    if not account:
        st.warning("⚠ Please create or load an account first!")
        return False
    try:
        args = [
            TransactionArgument(name, Serializer.str),
            TransactionArgument(premium, Serializer.u64),
            TransactionArgument(coverage, Serializer.u64),
        ]
        await _submit_entry_function(
            account,
            MODULE_ADDRESS,
            "MicroInsurance",
            "create_pool",
            args,
        )
        st.success("🎉 Pool created successfully!")
        return True
    except Exception as e:
        st.error(f"❌ Failed to create pool: {str(e)}")
        return False


async def join_pool_async(pool_id: int):
    account = get_account()
    if not account:
        st.warning("⚠ Please create or load an account first.")
        return False
    try:
        args = [TransactionArgument(pool_id, Serializer.u64)]
        await _submit_entry_function(
            account,
            MODULE_ADDRESS,
            "MicroInsurance",
            "join_pool",
            args,
        )
        st.success(f"✅ Joined pool #{pool_id} successfully!")
        return True
    except Exception as e:
        st.error(f"❌ Failed to join pool: {e}")
        return False


async def submit_claim_async(pool_id: int, amount: int, description: str):
    account = get_account()
    if not account:
        st.warning("⚠ Please create or load an account first.")
        return False
    try:
        args = [
            TransactionArgument(pool_id, Serializer.u64),
            TransactionArgument(amount, Serializer.u64),
            TransactionArgument(description, Serializer.str),
        ]
        await _submit_entry_function(
            account,
            MODULE_ADDRESS,
            "MicroInsurance",
            "submit_claim",
            args,
        )
        st.success(f"📩 Claim submitted for pool #{pool_id}!")
        return True
    except Exception as e:
        st.error(f"❌ Failed to submit claim: {e}")
        return False


async def vote_claim_async(claim_id: int, approve: bool):
    account = get_account()
    if not account:
        st.warning("⚠ Please create or load an account first.")
        return False
    try:
        args = [
            TransactionArgument(claim_id, Serializer.u64),
            TransactionArgument(approve, Serializer.bool),
        ]
        await _submit_entry_function(
            account,
            MODULE_ADDRESS,
            "MicroInsurance",
            "vote_on_claim",
            args,
        )
        st.success(f"🗳 Voted {'Approve' if approve else 'Reject'} on claim #{claim_id}.")
        return True
    except Exception as e:
        st.error(f"❌ Failed to vote on claim: {e}")
        return False


# ----- Sync wrappers for Streamlit buttons -----

def publish_pool(name: str, premium: int, coverage: int):
    return asyncio.run(publish_pool_async(name, premium, coverage))


def join_pool(pool_id: int):
    return asyncio.run(join_pool_async(pool_id))


def submit_claim(pool_id: int, amount: int, description: str):
    return asyncio.run(submit_claim_async(pool_id, amount, description))


def vote_claim(claim_id: int, approve: bool):
    return asyncio.run(vote_claim_async(claim_id, approve))


# =====================
# UI
# =====================
# =====================
# CUSTOM CSS (Techno-Luxury Theme)
# =====================
st.markdown(
    """
    <style>
    /* Global background with gradient */
    .stApp {
        background: linear-gradient(135deg, #0f2027, #203a43, #2c5364);
        color: #e0e0e0;
        font-family: 'Segoe UI', sans-serif;
    }

    /* Card-like containers */
    .block-container {
        padding: 2rem 2rem 2rem 2rem;
        border-radius: 16px;
    }

    /* Headers */
    h1, h2, h3 {
        color: #00ffe0 !important;
        text-shadow: 0px 0px 8px rgba(0, 255, 224, 0.8);
    }

    /* Buttons */
    button[kind="primary"] {
        background: linear-gradient(90deg, #00c6ff, #0072ff);
        color: white;
        border-radius: 12px;
        padding: 0.6rem 1.2rem;
        font-weight: bold;
    }
    button[kind="secondary"] {
        background: linear-gradient(90deg, #ff6a00, #ee0979);
        color: white;
        border-radius: 12px;
        padding: 0.6rem 1.2rem;
        font-weight: bold;
    }

    /* Inputs */
    .stTextInput > div > div > input,
    .stNumberInput input,
    .stTextArea textarea {
        background: #1e2a38;
        color: #e0e0e0;
        border-radius: 10px;
        border: 1px solid #00ffe0;
    }

    /* Footer */
    .footer {
        text-align: center;
        padding: 12px;
        font-size: 14px;
        color: #aaa;
        margin-top: 2rem;
    }
    </style>
    """,
    unsafe_allow_html=True
)

# =====================
# UI HEADER
# =====================
st.markdown(
    """
    <div style="text-align:center; padding: 20px; border-radius: 15px; 
                background: rgba(0,0,0,0.5); box-shadow: 0px 0px 15px rgba(0,255,224,0.3);">
        <h1>💎 MICRO-SURE</h1>
        <p style="font-size:18px;">A Futuristic Decentralized Insurance Platform on Aptos Blockchain</p>
    </div>
    """,
    unsafe_allow_html=True,
)

acct = get_account()
if acct:
    st.success(f"🔑 <b>Active Account:</b> {acct.address()}", icon="🔐")

st.markdown("---")

# =====================
# DASHBOARD SECTIONS
# =====================
col1, col2 = st.columns(2)

with col1:
    st.subheader("👤 Account")
    if not acct:
        st.info("No active account found. Create one below:")
        if st.button("✨ Create Demo Account", use_container_width=True):
            create_account()
    else:
        st.success("✅ Account ready. You can now create or join pools.")

    st.markdown("---")
    st.subheader("🏗 Create Pool")
    pool_name = st.text_input("Pool Name", placeholder="e.g., HealthCare Shield")
    premium_amount = st.number_input("💰 Premium (Octas)", min_value=1, value=100)
    coverage_amount = st.number_input("📦 Coverage (Octas)", min_value=1, value=1000)

    if st.button("🚀 Create Pool", type="primary", use_container_width=True):
        if pool_name.strip():
            publish_pool(pool_name, premium_amount, coverage_amount)
        else:
            st.warning("⚠ Please enter a pool name.")

with col2:
    st.subheader("🤝 Join Pool")
    join_pool_id = st.number_input("🔑 Pool ID to Join", min_value=1, value=1)
    if st.button("Join Pool", type="secondary", use_container_width=True):
        join_pool(join_pool_id)

st.markdown("---")

c3, c4 = st.columns(2)

with c3:
    st.subheader("📝 Submit Claim")
    claim_pool_id = st.number_input("🏛 Pool ID for Claim", min_value=1, value=1)
    claim_amount = st.number_input("💵 Claim Amount (Octas)", min_value=1, value=100)
    claim_desc = st.text_area("📜 Claim Description", placeholder="Describe your claim...")
    if st.button("📩 Submit Claim", type="primary", use_container_width=True):
        if claim_desc.strip():
            submit_claim(claim_pool_id, claim_amount, claim_desc)
        else:
            st.warning("⚠ Please provide a claim description.")

with c4:
    st.subheader("📊 Vote on Claims")
    vote_claim_id = st.number_input("🆔 Claim ID", min_value=1, value=1)
    vote_choice = st.radio("Cast Your Vote", ["✅ Approve", "❌ Reject"], horizontal=True)
    approve_bool = vote_choice.startswith("✅")
    if st.button("🗳 Cast Vote", type="secondary", use_container_width=True):
        vote_claim(vote_claim_id, approve_bool)

st.markdown(
    """
    <div class="footer">
        🚀 Built on <b>Aptos Blockchain</b> | Designed for <b>Next-Gen Insurance</b>
    </div>
    """,
    unsafe_allow_html=True
)
