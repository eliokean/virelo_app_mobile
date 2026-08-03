package com.virelo.virelo

import android.nfc.cardemulation.HostApduService
import android.os.Bundle
import android.util.Log
import java.nio.charset.StandardCharsets

class VireloHceService : HostApduService() {

    companion object {
        private const val TAG = "VireloHceService"
        
        // APDU Command header for SELECT AID: CLA=00, INS=A4, P1=04, P2=00
        // AID: F0010203040506 (7 bytes) -> Header: 00 A4 04 00 07 F0 01 02 03 04 05 06
        private val SELECT_APDU_HEADER = byteArrayOf(
            0x00.toByte(), 0xA4.toByte(), 0x04.toByte(), 0x00.toByte(), 0x07.toByte(),
            0xF0.toByte(), 0x01.toByte(), 0x02.toByte(), 0x03.toByte(), 0x04.toByte(), 0x05.toByte(), 0x06.toByte()
        )

        // Status words
        private val STATUS_SUCCESS = byteArrayOf(0x90.toByte(), 0x00.toByte())
        private val STATUS_FAILED = byteArrayOf(0x6F.toByte(), 0x00.toByte())

        // In-memory payment payload set from Flutter
        @Volatile
        var currentPayload: String? = null
    }

    override fun processCommandApdu(commandApdu: ByteArray?, extras: Bundle?): ByteArray {
        if (commandApdu == null) {
            return STATUS_FAILED
        }

        Log.d(TAG, "processCommandApdu received ${commandApdu.size} bytes: ${bytesToHex(commandApdu)}")

        // Check if command is SELECT AID
        if (isSelectAidApdu(commandApdu)) {
            val payload = currentPayload
            if (payload != null && payload.isNotEmpty()) {
                val payloadBytes = payload.toByteArray(StandardCharsets.UTF_8)
                // Return payload bytes followed by 90 00 (SW1 SW2)
                val response = ByteArray(payloadBytes.size + 2)
                System.arraycopy(payloadBytes, 0, response, 0, payloadBytes.size)
                response[response.size - 2] = 0x90.toByte()
                response[response.size - 1] = 0x00.toByte()
                Log.d(TAG, "Sending HCE response: ${payloadBytes.size} bytes payload")
                return response
            } else {
                Log.w(TAG, "HCE triggered but no active payload set")
                return STATUS_SUCCESS
            }
        }

        return STATUS_SUCCESS
    }

    override fun onDeactivated(reason: Int) {
        Log.d(TAG, "onDeactivated with reason: $reason")
    }

    private fun isSelectAidApdu(apdu: ByteArray): Boolean {
        if (apdu.size < SELECT_APDU_HEADER.size) return false
        for (i in SELECT_APDU_HEADER.indices) {
            if (apdu[i] != SELECT_APDU_HEADER[i]) return false
        }
        return true
    }

    private fun bytesToHex(bytes: ByteArray): String {
        val hexArray = "0123456789ABCDEF".toCharArray()
        val hexChars = CharArray(bytes.size * 2)
        for (j in bytes.indices) {
            val v = bytes[j].toInt() and 0xFF
            hexChars[j * 2] = hexArray[v ushr 4]
            hexChars[j * 2 + 1] = hexArray[v and 0x0F]
        }
        return String(hexChars)
    }
}
