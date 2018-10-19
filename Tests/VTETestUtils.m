//
//  VTETestsUtils.m
//  VirgilE3Kit
//
//  Created by Eugen Pivovarov on 10/19/18.
//

#import <Foundation/Foundation.h>
#import "VTETestUtils.h"

@implementation VTETestUtils

- (instancetype __nonnull)initWithCrypto:(VSMVirgilCrypto *)crypto consts:(VTETestsConst *)consts {
    self = [super init];
    if (self) {
        self.consts = consts;
        self.crypto = crypto;
    }
    return self;
}

- (NSString * __nonnull)getTokenStringWithIdentity:(NSString * __nonnull)identity error:(NSError * __nullable * __nullable)errorPtr {
    VSMVirgilPrivateKeyExporter *exporter = [[VSMVirgilPrivateKeyExporter alloc] initWithVirgilCrypto:self.crypto password:nil];
    NSData *privKey = [[NSData alloc] initWithBase64EncodedString:self.consts.apiPrivateKeyBase64 options:0];
    VSMVirgilPrivateKey *privateKey = (VSMVirgilPrivateKey *)[exporter importPrivateKeyFrom:privKey error:errorPtr];

    VSMVirgilAccessTokenSigner *tokenSigner = [[VSMVirgilAccessTokenSigner alloc] initWithVirgilCrypto:self.crypto];
    VSSJwtGenerator *generator = [[VSSJwtGenerator alloc] initWithApiKey:privateKey apiPublicKeyIdentifier:self.consts.apiPublicKeyId accessTokenSigner:tokenSigner appId:self.consts.applicationId ttl:1000];

    VSSJwt *jwtToken = [generator generateTokenWithIdentity:identity additionalData:nil error:errorPtr];

    NSString *strToken = [jwtToken stringRepresentation];

    return strToken;
}

- (id<VSSAccessToken> __nonnull)getTokenWithIdentity:(NSString * __nonnull)identity ttl:(NSTimeInterval)ttl error:(NSError * __nullable * __nullable)errorPtr {
    VSMVirgilPrivateKeyExporter *exporter = [[VSMVirgilPrivateKeyExporter alloc] initWithVirgilCrypto:self.crypto password:nil];
    NSData *privKey = [[NSData alloc] initWithBase64EncodedString:_consts.apiPrivateKeyBase64 options:0];
    VSMVirgilPrivateKey *privateKey = (VSMVirgilPrivateKey *)[exporter importPrivateKeyFrom:privKey error:errorPtr];

    VSMVirgilAccessTokenSigner *tokenSigner = [[VSMVirgilAccessTokenSigner alloc] initWithVirgilCrypto:self.crypto];
    VSSJwtGenerator *generator = [[VSSJwtGenerator alloc] initWithApiKey:privateKey apiPublicKeyIdentifier:self.consts.apiPublicKeyId accessTokenSigner:tokenSigner appId:self.consts.applicationId ttl:ttl];

    VSSJwt *jwtToken = [generator generateTokenWithIdentity:identity additionalData:nil error:errorPtr];
    return jwtToken;
}

- (VSSCard * __nullable)publishRandomCard {
    VSMVirgilKeyPair *keyPair = [self.crypto generateKeyPairAndReturnError:nil];
    NSData *exportedPublicKey = [self.crypto exportPublicKey:keyPair.publicKey];
    NSString *identity = [[NSUUID alloc] init].UUIDString;

    VSSRawCardContent *content = [[VSSRawCardContent alloc] initWithIdentity:identity publicKey:exportedPublicKey previousCardId:nil version:@"5.0" createdAt:NSDate.date];
    NSData *snapshot = [content snapshotAndReturnError:nil];

    VSSRawSignedModel *rawCard = [[VSSRawSignedModel alloc] initWithContentSnapshot:snapshot];

    NSString *strToken = [self getTokenStringWithIdentity:identity error:nil];

    VSMVirgilCardCrypto *cardCrypto = [[VSMVirgilCardCrypto alloc] initWithVirgilCrypto:self.crypto];
    VSSCardClient *cardClient = self.consts.serviceURL == nil ? [[VSSCardClient alloc] init] : [[VSSCardClient alloc] initWithServiceUrl:self.consts.serviceURL];

    VSSModelSigner *signer = [[VSSModelSigner alloc] initWithCardCrypto:cardCrypto];
    [signer selfSignWithModel:rawCard privateKey:keyPair.privateKey additionalData:nil error:nil];

    VSSRawSignedModel *responseRawCard = [cardClient publishCardWithModel:rawCard token:strToken error:nil];
    VSSCard *card = [VSSCardManager parseCardFrom:responseRawCard cardCrypto:cardCrypto error:nil];

    return card;
}

- (BOOL)isPublicKeysEqualWithPublicKeys1:(NSArray <VSMVirgilPublicKey *> * __nonnull)publicKeys1 publicKeys2:(NSArray <VSMVirgilPublicKey *> * __nonnull)publicKeys2 {

    for (VSMVirgilPublicKey* key1 in publicKeys1) {
        NSData *data1 = [self.crypto exportPublicKey:key1];
        BOOL found = false;
        for (VSMVirgilPublicKey* key2 in publicKeys2) {
            NSData *data2 = [self.crypto exportPublicKey:key2];
            if ([data1 isEqualToData:data2])
                found = true;
        }
        if (!found)
            return false;
    }

    return true;
}

@end