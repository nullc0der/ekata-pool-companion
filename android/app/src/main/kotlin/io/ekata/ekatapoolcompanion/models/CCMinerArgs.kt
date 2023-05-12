package io.ekata.ekatapoolcompanion.models

import android.os.Parcel
import android.os.Parcelable

class CCMinerArgs(
    val ccMinerBinaryVariant: String?,
    val algo: String?,
    val poolUrl: String?,
    val userName: String?,
    val rigId: String?,
    val passWord: String?,
    val threadCount: Int,
    val minerConfigPath: String?
) : Parcelable {
    private constructor(parcel: Parcel) : this(
        parcel.readString(),
        parcel.readString(),
        parcel.readString(),
        parcel.readString(),
        parcel.readString(),
        parcel.readString(),
        parcel.readInt(),
        parcel.readString()
    )

    override fun writeToParcel(parcel: Parcel, flags: Int) {
        parcel.writeString(ccMinerBinaryVariant)
        parcel.writeString(algo)
        parcel.writeString(poolUrl)
        parcel.writeString(userName)
        parcel.writeString(rigId)
        parcel.writeString(passWord)
        parcel.writeInt(threadCount)
        parcel.writeString(minerConfigPath)
    }

    override fun describeContents(): Int {
        return 0
    }

    companion object CREATOR : Parcelable.Creator<CCMinerArgs> {
        override fun createFromParcel(parcel: Parcel): CCMinerArgs {
            return CCMinerArgs(parcel)
        }

        override fun newArray(size: Int): Array<CCMinerArgs?> {
            return arrayOfNulls(size)
        }
    }
}